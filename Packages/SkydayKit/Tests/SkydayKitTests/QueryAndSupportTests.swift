import XCTest
@testable import SkydayKit

@MainActor
final class QueryAndSupportTests: XCTestCase {

    func testTodayOverviewOrderingAndCounts() async {
        let h = StoreHarness()
        let today = h.store.today
        h.add("Overdue old", due: today.adding(days: -3))
        h.add("Overdue new", due: today.adding(days: -1))
        h.add("Evening", due: today, time: TimeOfDay(hour: 20, minute: 0))
        h.add("Morning", due: today, time: TimeOfDay(hour: 8, minute: 0))
        h.add("Urgent untimed", due: today, priority: .high)
        h.add("Thursday", due: today.adding(days: 2))
        h.add("Next month", due: today.adding(days: 30))
        h.add("Someday")
        let done = h.add("Done", due: today)
        h.store.complete(done.id)

        let o = h.store.todayOverview
        XCTAssertEqual(o.overdue.map(\.title), ["Overdue old", "Overdue new"])
        XCTAssertEqual(o.dueToday.map(\.title), ["Urgent untimed", "Morning", "Evening"])
        XCTAssertEqual(o.upNext.map(\.title), ["Overdue old", "Overdue new", "Urgent untimed"])
        XCTAssertEqual(o.comingUp.map(\.title), ["Thursday"])
        XCTAssertEqual(o.doneCount, 1)
        XCTAssertEqual(o.plannedCount, 6)
        XCTAssertEqual(o.fraction, 1.0 / 6.0, accuracy: 0.0001)
    }

    func testEmptyOverview() async {
        let o = StoreHarness().store.todayOverview
        XCTAssertEqual(o.plannedCount, 0)
        XCTAssertEqual(o.fraction, 0)
        XCTAssertTrue(o.upNext.isEmpty)
    }

    func testOverdueByTimeToday() async {
        let h = StoreHarness() // 09:00
        let t = h.add("Standup", due: h.store.today, time: TimeOfDay(hour: 8, minute: 30))
        XCTAssertTrue(h.store.isOverdue(t))
        let later = h.add("Lunch", due: h.store.today, time: TimeOfDay(hour: 12, minute: 30))
        XCTAssertFalse(h.store.isOverdue(later))
    }

    func testAgendaProjectsRecurringOccurrences() async {
        let h = StoreHarness()
        let gym = h.add("Gym", due: h.store.today, repeat: .weekly(on: [3, 5])) // Tue, Thu
        let thursday = h.store.today.adding(days: 2)
        XCTAssertEqual(h.store.agenda(on: thursday).map(\.task.id), [gym.id])
        XCTAssertTrue(h.store.agenda(on: thursday)[0].isProjection)
        XCTAssertTrue(h.store.agenda(on: h.store.today.adding(days: 1)).isEmpty)
        let busy = h.store.busyDays(from: h.store.today, through: h.store.today.adding(days: 6))
        XCTAssertEqual(busy, [h.store.today, thursday, h.store.today.adding(days: 5)].reduce(into: Set<DayKey>()) { $0.insert($1) }.filter { $0.weekday == 3 || $0.weekday == 5 })
    }

    func testSearchIsCaseAndDiacriticInsensitive() async {
        let h = StoreHarness()
        h.add("Résumé update")
        let t = h.add("Groceries")
        var d = TaskDraft(task: t)
        d.subtasks = [Subtask(title: "Oat milk")]
        h.store.updateTask(t.id, with: d)
        XCTAssertEqual(h.store.search("resume").tasks.map(\.title), ["Résumé update"])
        XCTAssertEqual(h.store.search("OAT").tasks.map(\.title), ["Groceries"])
        XCTAssertEqual(h.store.search("univ").lists.map(\.name), ["University"])
        XCTAssertTrue(h.store.search("   ").isEmpty)
    }

    func testSortOptions() async {
        let h = StoreHarness()
        let today = h.store.today
        h.add("b later", due: today.adding(days: 2))
        h.add("a undated", priority: .high)
        h.add("c today 9", due: today, time: TimeOfDay(hour: 9, minute: 0))
        h.add("d today untimed", due: today, priority: .low)
        let id = h.inboxID
        XCTAssertEqual(h.store.tasks(in: id, sort: .dueDate).map(\.title), ["c today 9", "d today untimed", "b later", "a undated"])
        XCTAssertEqual(h.store.tasks(in: id, sort: .title).map(\.title), ["a undated", "b later", "c today 9", "d today untimed"])
        XCTAssertEqual(h.store.tasks(in: id, sort: .priority).first?.title, "a undated")
        XCTAssertEqual(h.store.tasks(in: id, sort: .smart).last?.title, "a undated")
    }

    func testWeekCompletionRate() async {
        let h = StoreHarness() // Tue 2026-11-03, weeks start Monday
        XCTAssertNil(h.store.weekCompletionRate, "nothing due or done yet")
        let a = h.add("Mon task", due: T.day(2026, 11, 2))
        h.add("Tue task", due: T.day(2026, 11, 3))
        h.add("Next week", due: T.day(2026, 11, 10))
        h.add("Last week", due: T.day(2026, 10, 30)) // before the week: excluded
        h.store.complete(a.id)
        XCTAssertEqual(h.store.weekCompletionRate ?? -1, 0.5, accuracy: 0.0001)
    }

    func testDeepLinks() async {
        let id = UUID()
        for link in [DeepLink.today, .newTask, .lists, .progress, .task(id)] {
            XCTAssertEqual(DeepLink(url: link.url), link)
        }
        XCTAssertNil(DeepLink(url: URL(string: "https://example.com/today")!))
        XCTAssertNil(DeepLink(url: URL(string: "skyday://task/not-a-uuid")!))
    }

    func testWidgetSnapshotContentAndMidnightRollover() async throws {
        let h = StoreHarness()
        let today = h.store.today
        h.add("Overdue", due: today.adding(days: -1))
        h.add("Today", due: today, time: TimeOfDay(hour: 15, minute: 0))
        h.add("Tomorrow", due: today.adding(days: 1))
        let snap = WidgetSnapshot.make(from: h.store.data, now: h.clock.now(), calendar: h.clock.calendar)
        XCTAssertEqual(snap.today.planned, 2)
        XCTAssertEqual(snap.today.upNext.map(\.title), ["Overdue", "Today"])
        XCTAssertTrue(snap.today.upNext[0].isOverdue)
        XCTAssertEqual(snap.tomorrow.planned, 3, "overdue + today's carry over + tomorrow's")
        XCTAssertEqual(snap.day(for: T.date(2026, 11, 4, 0, 5), calendar: h.clock.calendar)?.day, today.adding(days: 1))
        XCTAssertNil(snap.day(for: T.date(2026, 11, 6), calendar: h.clock.calendar))
        let decoded = try JSONFileStore.decoder().decode(WidgetSnapshot.self, from: JSONFileStore.encoder().encode(snap))
        XCTAssertEqual(decoded, snap)
    }

    func testRelativeDayFormatter() async {
        let today = T.day(2026, 11, 3)
        let en = Locale(identifier: "en_US")
        XCTAssertEqual(RelativeDayFormatter.string(for: today, today: today, locale: en), "Today")
        XCTAssertEqual(RelativeDayFormatter.string(for: today.adding(days: 1), today: today, locale: en), "Tomorrow")
        XCTAssertEqual(RelativeDayFormatter.string(for: today.adding(days: 3), today: today, locale: en), "Friday")
        XCTAssertEqual(RelativeDayFormatter.string(for: T.day(2026, 12, 25), today: today, locale: en), "Dec 25")
        XCTAssertEqual(RelativeDayFormatter.string(for: T.day(2027, 1, 2), today: today, locale: en), "Jan 2, 2027")
    }
}
