import Foundation
import XCTest
@testable import SkydayKit

enum T {
    static func calendar(_ tz: String = "America/New_York") -> Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: tz)!
        c.locale = Locale(identifier: "en_US_POSIX")
        return c
    }

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ mi: Int = 0, tz: String = "America/New_York") -> Date {
        calendar(tz).date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: mi))!
    }

    static func day(_ y: Int, _ m: Int, _ d: Int) -> DayKey { DayKey(year: y, month: m, day: d) }

    static func tempDir() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("skyday-tests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static func event(_ day: DayKey, task: UUID = UUID(), occurrence: DayKey? = nil) -> CompletionEvent {
        CompletionEvent(taskID: task, taskTitle: "t", listID: UUID(), occurrenceDay: occurrence,
                        completedAt: day.noonDate(in: calendar()), creditedDay: day)
    }

    /// `n` distinct completions on each given day.
    static func events(_ days: [DayKey], perDay n: Int) -> [CompletionEvent] {
        days.flatMap { d in (0..<n).map { _ in event(d) } }
    }

    static func settings(goal: Int = 3) -> AppSettings {
        AppSettings(goalHistory: [GoalChange(effectiveFrom: day(1970, 1, 1), goal: goal)])
    }
}

@MainActor
final class StoreHarness {
    let dir: URL
    let clock: FixedClock
    private(set) var store: SkydayStore

    init(at date: Date = T.date(2026, 11, 3, 9), calendar: Calendar = T.calendar()) {
        dir = T.tempDir()
        clock = FixedClock(date, calendar: calendar)
        store = SkydayStore(persistence: JSONFileStore(directory: dir), clock: clock)
    }

    /// Simulates app termination and cold relaunch from disk.
    @discardableResult
    func relaunch() -> SkydayStore {
        store = SkydayStore(persistence: JSONFileStore(directory: dir), clock: clock)
        return store
    }

    var inboxID: UUID { store.data.inbox.id }

    @discardableResult
    func add(_ title: String, due: DayKey? = nil, time: TimeOfDay? = nil, list: UUID? = nil, priority: Priority = .none,
             reminder: Int? = nil, repeat rule: RecurrenceRule? = nil) -> TaskItem {
        store.addTask(TaskDraft(title: title, listID: list ?? inboxID, priority: priority, dueDay: due, dueTime: time,
                                reminderMinutesBefore: reminder, recurrence: rule))!
    }
}
