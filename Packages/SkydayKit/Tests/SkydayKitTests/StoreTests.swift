import XCTest
@testable import SkydayKit

@MainActor
final class StoreTests: XCTestCase {

    // MARK: Persistence across relaunch

    func testFirstLaunchCreatesInboxAndStarterListsWithoutTasks() async {
        let h = StoreHarness()
        XCTAssertEqual(h.store.data.lists.count, 4)
        XCTAssertTrue(h.store.data.lists.contains { $0.isInbox })
        XCTAssertTrue(h.store.data.tasks.isEmpty, "no fake tasks in production data")
        XCTAssertEqual(h.relaunch().data.lists.map(\.id), h.store.data.lists.map(\.id))
    }

    func testCreateEditCompleteReopenDeletePersistAcrossRelaunch() async {
        let h = StoreHarness()
        let task = h.add("Finish portfolio case study", due: h.store.today, time: TimeOfDay(hour: 16, minute: 0), priority: .high)
        XCTAssertEqual(h.relaunch().task(task.id)?.title, "Finish portfolio case study")

        var draft = TaskDraft(task: h.store.task(task.id)!)
        draft.title = "Finish case study v2"
        draft.notes = "Use the new screenshots"
        draft.subtasks = [Subtask(title: "Export images"), Subtask(title: "   ")]
        h.store.updateTask(task.id, with: draft)
        let edited = h.relaunch().task(task.id)!
        XCTAssertEqual(edited.title, "Finish case study v2")
        XCTAssertEqual(edited.notes, "Use the new screenshots")
        XCTAssertEqual(edited.subtasks.map(\.title), ["Export images"], "blank subtasks are dropped")

        h.store.complete(task.id)
        XCTAssertTrue(h.relaunch().task(task.id)!.isCompleted)
        XCTAssertEqual(h.store.data.events.count, 1)

        h.store.reopen(task.id)
        let reopened = h.relaunch()
        XCTAssertFalse(reopened.task(task.id)!.isCompleted)
        XCTAssertTrue(reopened.data.events.isEmpty, "reopening removes the credit")

        h.store.deleteTask(task.id)
        XCTAssertNil(h.relaunch().task(task.id))
    }

    func testValidationRejectsWhitespaceTitle() async {
        let h = StoreHarness()
        XCTAssertNil(h.store.addTask(TaskDraft(title: "   \n ", listID: h.inboxID)))
        XCTAssertEqual(TaskDraft(title: " \t", listID: h.inboxID).validationError, .emptyTitle)
        XCTAssertTrue(h.store.data.tasks.isEmpty)
    }

    func testDraftNormalisationRules() async {
        let today = T.day(2026, 11, 3)
        let d = TaskDraft(title: "  Gym  ", listID: UUID(), dueDay: nil, dueTime: TimeOfDay(hour: 7, minute: 0),
                          reminderMinutesBefore: 10, recurrence: .daily).normalized(today: today)
        XCTAssertEqual(d.title, "Gym")
        XCTAssertEqual(d.dueDay, today, "repeating tasks need a start day")
        let noDate = TaskDraft(title: "x", listID: UUID(), dueTime: TimeOfDay(hour: 7, minute: 0), reminderMinutesBefore: 5).normalized(today: today)
        XCTAssertNil(noDate.dueTime)
        XCTAssertNil(noDate.reminderMinutesBefore, "a reminder without a date is impossible")
        let long = TaskDraft(title: String(repeating: "a", count: 1000), listID: UUID())
        XCTAssertEqual(long.trimmedTitle.count, TaskDraft.maxTitleLength)
    }

    func testInvalidListFallsBackToInbox() async {
        let h = StoreHarness()
        let t = h.add("Orphan", list: UUID())
        XCTAssertEqual(t.listID, h.inboxID)
    }

    // MARK: Completion, undo, idempotency

    func testDoubleCompletionIsIdempotent() async {
        let h = StoreHarness()
        let t = h.add("Read 20 pages", due: h.store.today)
        XCTAssertTrue(h.store.complete(t.id).didComplete)
        XCTAssertFalse(h.store.complete(t.id).didComplete)
        XCTAssertEqual(h.store.data.events.count, 1)
    }

    func testUndoCompletionRestoresTaskAndCredit() async {
        let h = StoreHarness()
        let t = h.add("Read", due: h.store.today)
        h.store.complete(t.id)
        XCTAssertNotNil(h.store.pendingUndo)
        h.store.undo()
        XCTAssertFalse(h.store.task(t.id)!.isCompleted)
        XCTAssertTrue(h.store.data.events.isEmpty)
        XCTAssertNil(h.store.pendingUndo)
        XCTAssertFalse(h.relaunch().task(t.id)!.isCompleted, "undo is persisted")
    }

    func testUndoDeleteRestoresTask() async {
        let h = StoreHarness()
        let t = h.add("Draft email")
        h.store.deleteTask(t.id)
        XCTAssertNil(h.store.task(t.id))
        h.store.undo()
        XCTAssertNotNil(h.store.task(t.id))
    }

    func testDeletingCompletedTaskKeepsHistory() async {
        let h = StoreHarness()
        let t = h.add("Done thing", due: h.store.today)
        h.store.complete(t.id)
        h.store.deleteTask(t.id)
        XCTAssertEqual(h.store.data.events.count, 1)
        XCTAssertEqual(h.store.streak.todayCompletions, 1)
    }

    func testGoalReachedFiresOncePerDay() async {
        let h = StoreHarness()
        let tasks = (0..<5).map { h.add("t\($0)", due: h.store.today) }
        XCTAssertFalse(h.store.complete(tasks[0].id).reachedDailyGoal)
        XCTAssertFalse(h.store.complete(tasks[1].id).reachedDailyGoal)
        let third = h.store.complete(tasks[2].id)
        XCTAssertTrue(third.reachedDailyGoal)
        XCTAssertEqual(third.newStreak, 1)
        XCTAssertFalse(h.store.complete(tasks[3].id).reachedDailyGoal)
        h.store.reopen(tasks[3].id)
        h.store.reopen(tasks[2].id)
        XCTAssertFalse(h.store.complete(tasks[2].id).reachedDailyGoal, "celebration does not replay the same day")
    }

    func testCompletionCreditsTheDayItHappenedAcrossMidnight() async {
        let h = StoreHarness(at: T.date(2026, 11, 3, 23, 59))
        let a = h.add("Late night", due: T.day(2026, 11, 3))
        h.store.complete(a.id)
        h.clock.advance(120) // 00:01 next day
        let b = h.add("After midnight", due: T.day(2026, 11, 3))
        h.store.complete(b.id)
        let byDay = StreakEngine.completionsByDay(h.store.data.events)
        XCTAssertEqual(byDay[T.day(2026, 11, 3)], 1)
        XCTAssertEqual(byDay[T.day(2026, 11, 4)], 1)
    }

    func testTimeZoneChangeDoesNotRewriteHistory() async {
        let h = StoreHarness(at: T.date(2026, 11, 3, 22))
        let t = h.add("Pack", due: T.day(2026, 11, 3))
        h.store.complete(t.id)
        // Fly to Tokyo: the same instant is already Nov 4 there.
        h.clock.calendar = T.calendar("Asia/Tokyo")
        let store = h.relaunch()
        XCTAssertEqual(store.today, T.day(2026, 11, 4))
        XCTAssertEqual(store.data.events.first?.creditedDay, T.day(2026, 11, 3))
        XCTAssertEqual(store.streak.current, 0, "yesterday had 1 of 3 so no streak; nothing shifted into today")
        XCTAssertEqual(store.streak.todayCompletions, 0)
    }

    // MARK: Recurring

    func testRecurringCompletionAdvancesWithoutDuplicatesAcrossRelaunches() async {
        let h = StoreHarness()
        let t = h.add("Review SwiftUI notes", due: h.store.today, time: TimeOfDay(hour: 20, minute: 0), repeat: .daily)
        let outcome = h.store.complete(t.id)
        XCTAssertTrue(outcome.didComplete)
        let after = h.store.task(t.id)!
        XCTAssertEqual(after.dueDay, h.store.today.adding(days: 1))
        XCTAssertFalse(after.isCompleted)
        for _ in 0..<10 { h.relaunch() }
        XCTAssertEqual(h.store.data.tasks.filter { $0.title == "Review SwiftUI notes" }.count, 1)
        XCTAssertEqual(h.store.data.events.count, 1)
        XCTAssertEqual(h.store.task(t.id)!.dueDay, T.day(2026, 11, 4))
    }

    func testRecurringRollsForwardOnNewDayIdempotently() async {
        let h = StoreHarness()
        let t = h.add("Stretch", due: h.store.today, repeat: .daily)
        h.clock.advance(3 * 86_400) // app not opened for three days
        h.store.refreshForNewDay()
        h.store.refreshForNewDay()
        XCTAssertEqual(h.store.task(t.id)!.dueDay, T.day(2026, 11, 6))
        XCTAssertEqual(h.relaunch().task(t.id)!.dueDay, T.day(2026, 11, 6))
        XCTAssertTrue(h.store.data.events.isEmpty, "skipped occurrences are not counted as done")
    }

    func testDayMarkerAdvancesOnRefresh() async {
        let h = StoreHarness(at: T.date(2026, 11, 3, 23, 59))
        XCTAssertEqual(h.store.currentDay, T.day(2026, 11, 3))
        h.clock.advance(120)
        h.store.refreshForNewDay()
        XCTAssertEqual(h.store.currentDay, T.day(2026, 11, 4))
        XCTAssertEqual(h.store.today, T.day(2026, 11, 4))
    }

    func testStaleNotificationActionIsIgnored() async {
        let h = StoreHarness()
        let t = h.add("Water plants", due: h.store.today, repeat: .daily)
        let occurrence = h.store.task(t.id)!.dueDay!
        h.store.complete(t.id)
        // A "Complete" action from the earlier notification arrives late.
        XCTAssertFalse(h.store.complete(t.id, expectedOccurrence: occurrence).didComplete)
        XCTAssertEqual(h.store.data.events.count, 1)
    }

    func testEditingRecurrenceResetsAnchor() async {
        let h = StoreHarness()
        let t = h.add("Gym", due: T.day(2026, 11, 3), repeat: .daily)
        var d = TaskDraft(task: h.store.task(t.id)!)
        d.recurrence = .weekly(on: [2]) // Mondays
        h.store.updateTask(t.id, with: d)
        let updated = h.store.task(t.id)!
        XCTAssertEqual(updated.dueDay, T.day(2026, 11, 9))
        XCTAssertEqual(updated.recurrenceAnchor, T.day(2026, 11, 3))
    }

    func testUndoRecurringCompletionRestoresOccurrence() async {
        let h = StoreHarness()
        let t = h.add("Journal", due: h.store.today, repeat: .daily)
        h.store.complete(t.id)
        h.store.undo()
        XCTAssertEqual(h.store.task(t.id)!.dueDay, h.store.today)
        XCTAssertTrue(h.store.data.events.isEmpty)
    }

    // MARK: Lists

    func testTwoListsHoldDistinctTasksAndMovingWorks() async {
        let h = StoreHarness()
        let work = h.store.addList(name: "Work", icon: "briefcase.fill", color: .sky)!
        let uni = h.store.addList(name: "Uni", icon: "graduationcap.fill", color: .steel)!
        let a = h.add("Deck", list: work.id)
        _ = h.add("Essay", list: uni.id)
        XCTAssertEqual(h.store.openCount(listID: work.id), 1)
        XCTAssertEqual(h.store.openCount(listID: uni.id), 1)
        h.store.moveTask(a.id, toList: uni.id)
        XCTAssertEqual(h.store.openCount(listID: work.id), 0)
        XCTAssertEqual(h.relaunch().openCount(listID: uni.id), 2)
    }

    func testDeletingListMovesTasksToInboxAndInboxIsPermanent() async {
        let h = StoreHarness()
        let list = h.store.addList(name: "Side project", icon: "laptopcomputer", color: .mint)!
        let t = h.add("Ship v1", list: list.id)
        h.store.deleteList(list.id)
        XCTAssertNil(h.store.list(list.id))
        XCTAssertEqual(h.store.task(t.id)!.listID, h.inboxID)
        h.store.deleteList(h.inboxID)
        XCTAssertNotNil(h.store.list(h.inboxID))
        h.store.undo()
        XCTAssertNotNil(h.store.list(list.id))
        XCTAssertEqual(h.store.task(t.id)!.listID, list.id)
    }

    func testListNameValidationAndRename() async {
        let h = StoreHarness()
        XCTAssertNil(h.store.addList(name: "  ", icon: "star.fill", color: .pink))
        let l = h.store.addList(name: "Gym", icon: "figure.run", color: .pink)!
        h.store.updateList(l.id, name: "Fitness", icon: "heart.fill", color: .amber)
        XCTAssertEqual(h.relaunch().list(l.id)?.name, "Fitness")
        XCTAssertEqual(h.store.list(l.id)?.color, .amber)
    }

    func testManualReorderPersists() async {
        let h = StoreHarness()
        let a = h.add("A"), b = h.add("B"), c = h.add("C")
        h.store.reorder(taskIDs: [c.id, a.id, b.id])
        XCTAssertEqual(h.relaunch().tasks(in: h.inboxID, sort: .manual).map(\.title), ["C", "A", "B"])
    }

    func testRescheduleToTomorrowAndSomeday() async {
        let h = StoreHarness()
        let t = h.add("Call bank", due: T.day(2026, 11, 1), time: TimeOfDay(hour: 10, minute: 0), reminder: 0)
        h.store.reschedule(t.id, to: h.store.today.adding(days: 1))
        XCTAssertEqual(h.store.task(t.id)!.dueDay, T.day(2026, 11, 4))
        XCTAssertEqual(h.store.task(t.id)!.dueTime, TimeOfDay(hour: 10, minute: 0))
        h.store.reschedule(t.id, to: nil)
        XCTAssertNil(h.store.task(t.id)!.reminderMinutesBefore)
    }

    // MARK: Goal & settings

    func testGoalChangePersistsAndDoesNotUnearnToday() async {
        let h = StoreHarness()
        for i in 0..<3 { h.store.complete(h.add("t\(i)", due: h.store.today).id) }
        XCTAssertEqual(h.store.streak.current, 1)
        h.store.setDailyGoal(5)
        XCTAssertEqual(h.store.streak.current, 1)
        XCTAssertEqual(h.relaunch().settings.dailyGoal, 5)
        h.store.setDailyGoal(99)
        XCTAssertEqual(h.store.settings.dailyGoal, AppSettings.goalRange.upperBound)
    }

    func testUpdateSettingsCannotBypassGoalHistory() async {
        let h = StoreHarness()
        h.store.updateSettings { $0.goalHistory = []; $0.firstWeekday = 1 }
        XCTAssertEqual(h.store.settings.firstWeekday, 1)
        XCTAssertEqual(h.store.settings.goalHistory.count, 1)
    }

    // MARK: Robustness

    func testCorruptFileIsQuarantinedNotOverwritten() async throws {
        let dir = T.tempDir()
        let file = dir.appendingPathComponent("skyday.json")
        try Data("{ not json".utf8).write(to: file)
        let store = SkydayStore(persistence: JSONFileStore(directory: dir), clock: FixedClock(T.date(2026, 11, 3), calendar: T.calendar()))
        XCTAssertNotNil(store.recoveryNotice)
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        XCTAssertTrue(files.contains { $0.hasPrefix("skyday-unreadable-") }, "original bytes are preserved: \(files)")
    }

    func testNewerSchemaIsReadOnlyAndUntouched() async throws {
        let dir = T.tempDir()
        let file = dir.appendingPathComponent("skyday.json")
        let future = Data(#"{"schemaVersion": 99, "lists": [], "tasks": [], "events": [], "settings": {}}"#.utf8)
        try future.write(to: file)
        let store = SkydayStore(persistence: JSONFileStore(directory: dir), clock: FixedClock(T.date(2026, 11, 3), calendar: T.calendar()))
        XCTAssertTrue(store.isReadOnly)
        store.addTask(TaskDraft(title: "x", listID: store.data.inbox.id))
        XCTAssertEqual(try Data(contentsOf: file), future)
    }

    func testSaveFailureIsReportedAndRecovered() async {
        let mem = InMemoryStore()
        let store = SkydayStore(persistence: mem, clock: FixedClock(T.date(2026, 11, 3), calendar: T.calendar()))
        mem.failNextSave = true
        store.addTask(TaskDraft(title: "A", listID: store.data.inbox.id))
        XCTAssertNotNil(store.lastSaveError)
        store.addTask(TaskDraft(title: "B", listID: store.data.inbox.id))
        XCTAssertNil(store.lastSaveError)
        XCTAssertEqual(mem.stored?.tasks.count, 2, "the next successful save includes the earlier change")
    }

    func testOldDocumentWithMissingFieldsDecodes() async throws {
        let inbox = UUID()
        let json = """
        {"lists":[{"id":"\(inbox)","name":"Inbox","icon":"tray.fill","color":"sky","sortOrder":0,"isInbox":true,"createdAt":"2026-01-01T10:00:00Z"}],
         "tasks":[{"id":"\(UUID())","title":"Legacy","listID":"\(UUID())","createdAt":"2026-01-01T10:00:00Z"}],
         "events":[],"settings":{}}
        """
        let data = try JSONFileStore.decode(Data(json.utf8))
        XCTAssertEqual(data.tasks.first?.priority, Priority.none)
        XCTAssertEqual(data.tasks.first?.listID, inbox, "orphaned task repaired into Inbox")
        XCTAssertEqual(data.settings.dailyGoal, 3)
    }

    func testExportImportRoundTrip() async throws {
        let h = StoreHarness()
        h.add("Keep me", due: h.store.today, repeat: .weekdaysOnly)
        let backup = try h.store.exportBackup()
        h.store.eraseAllData()
        XCTAssertTrue(h.store.data.tasks.isEmpty)
        try h.store.importBackup(backup)
        XCTAssertEqual(h.relaunch().data.tasks.map(\.title), ["Keep me"])
    }

    func testImportOfGarbageThrowsAndChangesNothing() async {
        let h = StoreHarness()
        h.add("Safe")
        XCTAssertThrowsError(try h.store.importBackup(Data("nope".utf8)))
        XCTAssertEqual(h.store.data.tasks.map(\.title), ["Safe"])
    }

    func testOnCommitFiresForMutationsAndUndo() async {
        let h = StoreHarness()
        var commits = 0
        h.store.onCommit = { _ in commits += 1 }
        let t = h.add("x")
        h.store.deleteTask(t.id)
        h.store.undo()
        XCTAssertEqual(commits, 3)
    }

    func testHundredsOfTasksStayFast() async {
        let h = StoreHarness()
        for i in 0..<600 { h.add("Task \(i)", due: h.store.today.adding(days: i % 14 - 3), priority: Priority(rawValue: i % 4)!) }
        measure {
            _ = h.store.todayOverview
            _ = h.store.streak
            _ = h.store.search("Task 59")
        }
        XCTAssertEqual(h.relaunch().data.tasks.count, 600)
    }
}
