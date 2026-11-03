import XCTest
@testable import SkydayKit

final class ReminderPlannerTests: XCTestCase {
    let cal = T.calendar()
    let now = T.date(2026, 11, 3, 9)
    let inbox = TaskList(name: "Inbox", icon: "tray.fill", color: .sky, sortOrder: 0, isInbox: true, createdAt: Date())

    private func data(_ tasks: [TaskItem], settings: AppSettings = AppSettings()) -> AppData {
        AppData(lists: [inbox], tasks: tasks, settings: settings)
    }

    private func task(_ title: String = "Essay", due: DayKey? = T.day(2026, 11, 3), time: TimeOfDay? = TimeOfDay(hour: 16, minute: 0),
                      reminder: Int? = 15, rule: RecurrenceRule? = nil, completed: Bool = false) -> TaskItem {
        RecurrenceEngine.normalized(TaskItem(title: title, listID: inbox.id, dueDay: due, dueTime: time, reminderMinutesBefore: reminder,
                                             recurrence: rule, isCompleted: completed, createdAt: now))
    }

    func testTimedReminderUsesOffset() {
        let t = task()
        let plan = ReminderPlanner.plan(data([t]), now: now, calendar: cal)
        XCTAssertEqual(plan.count, 1)
        XCTAssertEqual(plan[0].id, "skyday.task.\(t.id.uuidString).2026-11-03")
        XCTAssertEqual(plan[0].fireDate, T.date(2026, 11, 3, 15, 45))
        XCTAssertEqual(plan[0].taskID, t.id)
        XCTAssertTrue(plan[0].body.contains("Inbox"))
    }

    func testDateOnlyReminderUsesDefaultTime() {
        var s = AppSettings()
        s = AppSettings(goalHistory: s.goalHistory, defaultReminderTime: TimeOfDay(hour: 18, minute: 30))
        let plan = ReminderPlanner.plan(data([task(time: nil)], settings: s), now: now, calendar: cal)
        XCTAssertEqual(plan.first?.fireDate, T.date(2026, 11, 3, 18, 30))
    }

    func testPastCompletedAndReminderlessTasksAreSkipped() {
        let tasks = [task(time: TimeOfDay(hour: 8, minute: 0)), task(completed: true), task(reminder: nil), task(due: nil)]
        XCTAssertTrue(ReminderPlanner.plan(data(tasks), now: now, calendar: cal).isEmpty)
    }

    func testRecurringPlansNextOccurrencesWithinHorizon() {
        let t = task("Gym", time: TimeOfDay(hour: 18, minute: 0), reminder: 0, rule: .daily)
        let plan = ReminderPlanner.plan(data([t]), now: now, calendar: cal)
        XCTAssertEqual(plan.map(\.id), ["03", "04", "05", "06"].map { "skyday.task.\(t.id.uuidString).2026-11-\($0)" })
    }

    func testReminderKeepsWallClockTimeAcrossDST() {
        // Weekly Sunday 9:00 reminder spanning the Nov 1 fall-back transition.
        let early = T.date(2026, 10, 30, 9)
        let t = TaskItem(title: "Plan week", listID: inbox.id, dueDay: T.day(2026, 10, 25), dueTime: TimeOfDay(hour: 9, minute: 0),
                         reminderMinutesBefore: 0, recurrence: .weekly(), recurrenceAnchor: T.day(2026, 10, 25), createdAt: early)
        let rolled = RecurrenceEngine.normalized(TaskItem(title: t.title, listID: t.listID, dueDay: T.day(2026, 11, 1), dueTime: t.dueTime,
                                                          reminderMinutesBefore: 0, recurrence: .weekly(), recurrenceAnchor: T.day(2026, 10, 25), createdAt: early))
        let plan = ReminderPlanner.plan(data([rolled]), now: early, calendar: cal)
        XCTAssertFalse(plan.isEmpty)
        for p in plan { XCTAssertEqual(cal.component(.hour, from: p.fireDate), 9, "\(p.fireDate)") }
    }

    func testPlanIsCappedAtSystemLimitSoonestFirst() {
        let tasks = (0..<100).map { i in task("T\(i)", due: T.day(2026, 11, 3).adding(days: i % 7), time: TimeOfDay(hour: 10 + i % 10, minute: 0)) }
        let plan = ReminderPlanner.plan(data(tasks), now: now, calendar: cal)
        XCTAssertEqual(plan.count, ReminderPlanner.systemPendingLimit)
        XCTAssertEqual(plan.map(\.fireDate), plan.map(\.fireDate).sorted())
    }

    func testPlanningIsDeterministic() {
        let d = data([task(), task("Gym", rule: .daily)])
        XCTAssertEqual(ReminderPlanner.plan(d, now: now, calendar: cal), ReminderPlanner.plan(d, now: now, calendar: cal))
    }

    func testDiffAddsChangesAndRemovesOnlyOwnRequests() {
        let a = PlannedNotification(id: "skyday.task.a", kind: .task, taskID: nil, title: "A", body: "b", fireDate: now)
        let b = PlannedNotification(id: "skyday.task.b", kind: .task, taskID: nil, title: "B", body: "b", fireDate: now)
        let pending = [
            PendingNotification(id: "skyday.task.a", fingerprint: a.fingerprint),           // unchanged
            PendingNotification(id: "skyday.task.b", fingerprint: "old"),                   // changed
            PendingNotification(id: "skyday.task.gone", fingerprint: "x"),                  // deleted task
            PendingNotification(id: "com.other.system", fingerprint: "y")                   // not ours
        ]
        let diff = ReminderPlanner.diff(pending: pending, desired: [a, b])
        XCTAssertEqual(diff.remove, ["skyday.task.b", "skyday.task.gone"])
        XCTAssertEqual(diff.add.map(\.id), ["skyday.task.b"])
        // Applying the same plan again is a no-op.
        let settled = [PendingNotification(id: a.id, fingerprint: a.fingerprint), PendingNotification(id: b.id, fingerprint: b.fingerprint)]
        let again = ReminderPlanner.diff(pending: settled, desired: [a, b])
        XCTAssertTrue(again.remove.isEmpty && again.add.isEmpty)
    }

    func testDigestsSkipEmptyDaysAndCountCarryOvers() {
        let s = AppSettings(morningDigest: DigestSetting(enabled: true, time: TimeOfDay(hour: 8, minute: 0)),
                            eveningDigest: DigestSetting(enabled: true, time: TimeOfDay(hour: 20, minute: 0)))
        let overdue = task("Overdue", due: T.day(2026, 11, 1), reminder: nil)
        let thursday = task("Thursday", due: T.day(2026, 11, 5), reminder: nil)
        let plan = ReminderPlanner.plan(data([overdue, thursday], settings: s), now: now, calendar: cal)
        let morning = plan.filter { $0.kind == .morningDigest }
        let evening = plan.filter { $0.kind == .eveningDigest }
        // Today's 8:00 already passed; overdue carries over every future day.
        XCTAssertEqual(morning.first?.id, "skyday.morningDigest.2026-11-04")
        XCTAssertEqual(morning.first?.body, "One task today: Overdue")
        XCTAssertTrue(morning.contains { $0.id.hasSuffix("2026-11-05") && $0.body.hasPrefix("2 tasks") })
        XCTAssertEqual(evening.first?.id, "skyday.eveningDigest.2026-11-03")

        // With nothing planned, no digest is scheduled at all.
        XCTAssertTrue(ReminderPlanner.plan(data([], settings: s), now: now, calendar: cal).isEmpty)
    }

    func testSnoozeIsPlannedAndClearedOnCompletion() {
        var t = task(reminder: nil)
        t.snoozedUntil = now.addingTimeInterval(3600)
        let plan = ReminderPlanner.plan(data([t]), now: now, calendar: cal)
        XCTAssertEqual(plan.map(\.kind), [.snooze])
        t.isCompleted = true
        XCTAssertTrue(ReminderPlanner.plan(data([t]), now: now, calendar: cal).isEmpty)
    }

    @MainActor
    func testEditingTaskChangesPlanIdempotently() async {
        let h = StoreHarness()
        let t = h.add("Lab report", due: h.store.today, time: TimeOfDay(hour: 17, minute: 0), reminder: 30)
        let first = ReminderPlanner.plan(h.store.data, now: h.clock.now(), calendar: h.clock.calendar)
        XCTAssertEqual(first.map(\.fireDate), [T.date(2026, 11, 3, 16, 30)])
        var d = TaskDraft(task: t)
        d.dueTime = TimeOfDay(hour: 19, minute: 0)
        h.store.updateTask(t.id, with: d)
        let second = ReminderPlanner.plan(h.store.data, now: h.clock.now(), calendar: h.clock.calendar)
        XCTAssertEqual(second.map(\.id), first.map(\.id), "same stable id, replaced in place")
        XCTAssertEqual(second.map(\.fireDate), [T.date(2026, 11, 3, 18, 30)])
        let diff = ReminderPlanner.diff(pending: first.map { PendingNotification(id: $0.id, fingerprint: $0.fingerprint) }, desired: second)
        XCTAssertEqual(diff.remove, [first[0].id])
        XCTAssertEqual(diff.add.count, 1)
        h.store.complete(t.id)
        XCTAssertTrue(ReminderPlanner.plan(h.store.data, now: h.clock.now(), calendar: h.clock.calendar).isEmpty, "completed -> cancelled")
    }
}
