import Foundation

// MARK: - Clock

/// Time source. Inject a fixed clock in tests to make day boundaries deterministic.
public protocol SkydayClock: AnyObject {
    func now() -> Date
    var calendar: Calendar { get }
}

public final class SystemClock: SkydayClock {
    public init() {}
    public func now() -> Date { Date() }
    /// `autoupdatingCurrent` follows time-zone and locale changes while the app runs.
    public var calendar: Calendar { Calendar.autoupdatingCurrent }
}

public final class FixedClock: SkydayClock {
    public var current: Date
    public var calendar: Calendar

    public init(_ date: Date, calendar: Calendar) {
        self.current = date
        self.calendar = calendar
    }

    public func now() -> Date { current }
    public func advance(_ seconds: TimeInterval) { current = current.addingTimeInterval(seconds) }
}

// MARK: - Shared identifiers

public enum SkydayIdentifiers {
    /// Must match the App Group in Skyday.entitlements and SkydayWidget.entitlements.
    /// Change it together with your bundle identifier prefix before signing.
    public static let appGroup = "group.com.skyday.app"
    public static let urlScheme = "skyday"
    public static let widgetKind = "SkydayTodayWidget"
    public static let reminderCategory = "SKYDAY_TASK_REMINDER"
    public static let completeAction = "SKYDAY_COMPLETE"
    public static let snoozeAction = "SKYDAY_SNOOZE_1H"
    public static let taskIDKey = "taskID"
    public static let fingerprintKey = "fingerprint"
}

// MARK: - Deep links

public enum DeepLink: Equatable, Sendable {
    case today
    case newTask
    case task(UUID)
    case lists
    case progress

    public init?(url: URL) {
        guard url.scheme?.lowercased() == SkydayIdentifiers.urlScheme else { return nil }
        let host = url.host?.lowercased() ?? ""
        let parts = url.pathComponents.filter { $0 != "/" }
        switch host {
        case "today", "": self = .today
        case "new": self = .newTask
        case "lists": self = .lists
        case "progress": self = .progress
        case "task":
            guard let raw = parts.first, let id = UUID(uuidString: raw) else { return nil }
            self = .task(id)
        default: return nil
        }
    }

    public var url: URL {
        let base = "\(SkydayIdentifiers.urlScheme)://"
        switch self {
        case .today: return URL(string: base + "today")!
        case .newTask: return URL(string: base + "new")!
        case .lists: return URL(string: base + "lists")!
        case .progress: return URL(string: base + "progress")!
        case .task(let id): return URL(string: base + "task/\(id.uuidString)")!
        }
    }
}

// MARK: - Draft & validation

/// Editable copy of a task used by the Add/Edit sheet. Validation lives here, not in views.
public struct TaskDraft: Hashable, Sendable {
    public static let maxTitleLength = 300

    public var title: String
    public var notes: String
    public var listID: UUID
    public var priority: Priority
    public var dueDay: DayKey?
    public var dueTime: TimeOfDay?
    public var reminderMinutesBefore: Int?
    public var recurrence: RecurrenceRule?
    public var subtasks: [Subtask]

    public init(title: String = "", notes: String = "", listID: UUID, priority: Priority = .none, dueDay: DayKey? = nil,
                dueTime: TimeOfDay? = nil, reminderMinutesBefore: Int? = nil, recurrence: RecurrenceRule? = nil,
                subtasks: [Subtask] = []) {
        self.title = title
        self.notes = notes
        self.listID = listID
        self.priority = priority
        self.dueDay = dueDay
        self.dueTime = dueTime
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrence = recurrence
        self.subtasks = subtasks
    }

    public init(task: TaskItem) {
        self.init(title: task.title, notes: task.notes, listID: task.listID, priority: task.priority, dueDay: task.dueDay,
                  dueTime: task.dueTime, reminderMinutesBefore: task.reminderMinutesBefore, recurrence: task.recurrence,
                  subtasks: task.subtasks)
    }

    public enum ValidationError: Error, Equatable, Sendable {
        case emptyTitle
        public var message: String { "Give the task a name." }
    }

    /// Single-line title: inner line breaks become spaces, ends trimmed, length capped.
    public var trimmedTitle: String {
        let oneLine = title.components(separatedBy: .newlines).joined(separator: " ")
        return String(oneLine.trimmingCharacters(in: .whitespacesAndNewlines).prefix(TaskDraft.maxTitleLength))
    }

    public var validationError: ValidationError? { trimmedTitle.isEmpty ? .emptyTitle : nil }
    public var isValid: Bool { validationError == nil }

    /// Applies dependent-field rules: time/reminder/repeat need a date; empty subtasks dropped.
    public func normalized(today: DayKey) -> TaskDraft {
        var d = self
        d.title = trimmedTitle
        d.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if d.recurrence != nil && d.dueDay == nil { d.dueDay = today }
        if d.dueDay == nil {
            d.dueTime = nil
            d.reminderMinutesBefore = nil
        }
        d.subtasks = d.subtasks
            .map { Subtask(id: $0.id, title: $0.title.trimmingCharacters(in: .whitespacesAndNewlines), isDone: $0.isDone) }
            .filter { !$0.title.isEmpty }
        return d
    }
}

// MARK: - Widget snapshot

/// Small, precomputed document the widget reads from the App Group container. The widget
/// never opens the full store, so it cannot race the app's writes.
public struct WidgetSnapshot: Codable, Hashable, Sendable {
    public struct Item: Codable, Hashable, Sendable, Identifiable {
        public var id: UUID
        public var title: String
        public var listName: String
        public var listColor: ListColor
        public var dueTime: TimeOfDay?
        public var isOverdue: Bool
        public var priority: Priority

        public init(id: UUID, title: String, listName: String, listColor: ListColor, dueTime: TimeOfDay?,
                    isOverdue: Bool, priority: Priority) {
            self.id = id
            self.title = title
            self.listName = listName
            self.listColor = listColor
            self.dueTime = dueTime
            self.isOverdue = isOverdue
            self.priority = priority
        }
    }

    public struct Day: Codable, Hashable, Sendable {
        public var day: DayKey
        public var done: Int
        public var planned: Int
        public var upNext: [Item]

        public init(day: DayKey, done: Int, planned: Int, upNext: [Item]) {
            self.day = day
            self.done = done
            self.planned = planned
            self.upNext = upNext
        }
    }

    public var generatedAt: Date
    public var today: Day
    /// Best-known view of tomorrow, shown by the widget after midnight until the app runs.
    public var tomorrow: Day
    public var streak: Int
    public var goal: Int
    public var todayCompletions: Int

    public static let fileName = "widget-snapshot.json"

    public static func make(from data: AppData, now: Date, calendar: Calendar) -> WidgetSnapshot {
        let today = DayKey(now, calendar: calendar)
        let overview = TaskQueries.todayOverview(data, today: today)
        let summary = StreakEngine.summary(events: data.events, settings: data.settings, today: today)
        func item(_ t: TaskItem, day: DayKey) -> Item {
            let list = data.list(t.listID)
            return Item(id: t.id, title: t.title, listName: list?.name ?? "Inbox", listColor: list?.color ?? .sky,
                        dueTime: t.dueTime, isOverdue: (t.dueDay ?? day) < day, priority: t.priority)
        }
        let tomorrowDay = today.adding(days: 1)
        let tomorrowTasks = ReminderPlanner.plannedTasks(data, on: tomorrowDay, today: tomorrowDay)
        return WidgetSnapshot(
            generatedAt: now,
            today: Day(day: today, done: overview.doneCount, planned: overview.plannedCount,
                       upNext: overview.allActionable.prefix(3).map { item($0, day: today) }),
            tomorrow: Day(day: tomorrowDay, done: 0, planned: tomorrowTasks.count,
                          upNext: tomorrowTasks.prefix(3).map { item($0, day: tomorrowDay) }),
            streak: summary.current, goal: summary.todayGoal, todayCompletions: summary.todayCompletions)
    }

    /// The day view valid at `date` (today's, or tomorrow's after midnight).
    public func day(for date: Date, calendar: Calendar) -> Day? {
        let key = DayKey(date, calendar: calendar)
        if key == today.day { return today }
        if key == tomorrow.day { return tomorrow }
        return nil
    }

    public static let placeholder = WidgetSnapshot(
        generatedAt: Date(timeIntervalSince1970: 0),
        today: Day(day: DayKey(year: 2026, month: 1, day: 1), done: 0, planned: 0, upNext: []),
        tomorrow: Day(day: DayKey(year: 2026, month: 1, day: 2), done: 0, planned: 0, upNext: []),
        streak: 0, goal: AppSettings.defaultGoal, todayCompletions: 0)
}
