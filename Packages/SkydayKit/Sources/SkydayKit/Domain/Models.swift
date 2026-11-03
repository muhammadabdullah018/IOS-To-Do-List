import Foundation

// MARK: - Priority

public enum Priority: Int, Codable, CaseIterable, Comparable, Sendable, Identifiable {
    case none = 0, low = 1, medium = 2, high = 3

    public var id: Int { rawValue }
    public static func < (lhs: Priority, rhs: Priority) -> Bool { lhs.rawValue < rhs.rawValue }

    public var label: String {
        switch self {
        case .none: return "None"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

// MARK: - Subtask

public struct Subtask: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var isDone: Bool

    public init(id: UUID = UUID(), title: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

// MARK: - Recurrence

/// A calendar-based repeat rule. Occurrences are anchored to `TaskItem.recurrenceAnchor`
/// (the series start day) and never computed with naive 24-hour addition.
public struct RecurrenceRule: Codable, Hashable, Sendable {
    public enum Frequency: String, Codable, CaseIterable, Sendable {
        case daily, weekly, monthly, yearly
    }

    public var frequency: Frequency
    /// Every `interval` days / weeks / months / years. Always >= 1.
    public var interval: Int
    /// Weekly only: weekdays (1 = Sunday ... 7 = Saturday). Empty means "the anchor's weekday".
    public var weekdays: [Int]

    public init(frequency: Frequency, interval: Int = 1, weekdays: [Int] = []) {
        self.frequency = frequency
        self.interval = max(1, interval)
        self.weekdays = Array(Set(weekdays.filter { (1...7).contains($0) })).sorted()
    }

    public static let daily = RecurrenceRule(frequency: .daily)
    public static let weekdaysOnly = RecurrenceRule(frequency: .weekly, weekdays: [2, 3, 4, 5, 6])
    public static func weekly(on weekdays: [Int] = []) -> RecurrenceRule { RecurrenceRule(frequency: .weekly, weekdays: weekdays) }
    public static let monthly = RecurrenceRule(frequency: .monthly)
    public static let yearly = RecurrenceRule(frequency: .yearly)

    public var summary: String {
        let unit: String
        switch frequency {
        case .daily: unit = interval == 1 ? "Every day" : "Every \(interval) days"
        case .weekly:
            if weekdays == [2, 3, 4, 5, 6] && interval == 1 { return "Every weekday" }
            let base = interval == 1 ? "Every week" : "Every \(interval) weeks"
            if weekdays.isEmpty { unit = base } else {
                let names = weekdays.map { RecurrenceRule.shortWeekdayNames[$0 - 1] }.joined(separator: ", ")
                unit = "\(base) on \(names)"
            }
        case .monthly: unit = interval == 1 ? "Every month" : "Every \(interval) months"
        case .yearly: unit = interval == 1 ? "Every year" : "Every \(interval) years"
        }
        return unit
    }

    public static let shortWeekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
}

// MARK: - Task

public struct TaskItem: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var notes: String
    public var listID: UUID
    public var priority: Priority
    /// Due calendar day (floating). For recurring tasks this is the *current occurrence*.
    public var dueDay: DayKey?
    /// Optional wall-clock due time. Requires `dueDay`.
    public var dueTime: TimeOfDay?
    /// Minutes before `dueTime` to remind. For date-only tasks the reminder fires at
    /// `AppSettings.defaultReminderTime` on the due day and this offset is ignored.
    /// `nil` means no reminder.
    public var reminderMinutesBefore: Int?
    public var recurrence: RecurrenceRule?
    /// Series start day. Occurrences are computed from this anchor.
    public var recurrenceAnchor: DayKey?
    public var subtasks: [Subtask]
    /// Only ever true for non-recurring tasks. Recurring tasks advance instead.
    public var isCompleted: Bool
    public var completedAt: Date?
    /// Set by the "Remind me in 1 hour" notification action; cleared on completion.
    public var snoozedUntil: Date?
    public var createdAt: Date
    public var updatedAt: Date
    /// Manual ordering inside a list (ascending).
    public var sortOrder: Double

    public init(
        id: UUID = UUID(), title: String, notes: String = "", listID: UUID, priority: Priority = .none,
        dueDay: DayKey? = nil, dueTime: TimeOfDay? = nil, reminderMinutesBefore: Int? = nil,
        recurrence: RecurrenceRule? = nil, recurrenceAnchor: DayKey? = nil, subtasks: [Subtask] = [],
        isCompleted: Bool = false, completedAt: Date? = nil, snoozedUntil: Date? = nil,
        createdAt: Date, updatedAt: Date? = nil, sortOrder: Double = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.listID = listID
        self.priority = priority
        self.dueDay = dueDay
        self.dueTime = dueTime
        self.reminderMinutesBefore = reminderMinutesBefore
        self.recurrence = recurrence
        self.recurrenceAnchor = recurrenceAnchor
        self.subtasks = subtasks
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.snoozedUntil = snoozedUntil
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.sortOrder = sortOrder
    }

    public var isRecurring: Bool { recurrence != nil }
    public var hasReminder: Bool { reminderMinutesBefore != nil && dueDay != nil }
    public var subtaskProgress: (done: Int, total: Int) { (subtasks.filter(\.isDone).count, subtasks.count) }

    public func isOverdue(today: DayKey, now: Date, calendar: Calendar) -> Bool {
        guard !isCompleted, let due = dueDay else { return false }
        if due < today { return true }
        if due == today, let time = dueTime { return due.date(at: time, in: calendar) < now }
        return false
    }

    // Tolerant decoding: new optional fields default instead of failing old files.
    enum CodingKeys: String, CodingKey {
        case id, title, notes, listID, priority, dueDay, dueTime, reminderMinutesBefore, recurrence,
             recurrenceAnchor, subtasks, isCompleted, completedAt, snoozedUntil, createdAt, updatedAt, sortOrder
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        listID = try c.decode(UUID.self, forKey: .listID)
        priority = try c.decodeIfPresent(Priority.self, forKey: .priority) ?? .none
        dueDay = try c.decodeIfPresent(DayKey.self, forKey: .dueDay)
        dueTime = try c.decodeIfPresent(TimeOfDay.self, forKey: .dueTime)
        reminderMinutesBefore = try c.decodeIfPresent(Int.self, forKey: .reminderMinutesBefore)
        recurrence = try c.decodeIfPresent(RecurrenceRule.self, forKey: .recurrence)
        recurrenceAnchor = try c.decodeIfPresent(DayKey.self, forKey: .recurrenceAnchor)
        subtasks = try c.decodeIfPresent([Subtask].self, forKey: .subtasks) ?? []
        isCompleted = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        completedAt = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        snoozedUntil = try c.decodeIfPresent(Date.self, forKey: .snoozedUntil)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
        sortOrder = try c.decodeIfPresent(Double.self, forKey: .sortOrder) ?? 0
    }
}

// MARK: - List

public enum ListColor: String, Codable, CaseIterable, Sendable, Identifiable {
    case sky, pink, steel, lagoon, ink, mint, amber
    public var id: String { rawValue }

    /// sRGB hex. Sky and pink are the exact brand colors; the rest are derived tints.
    public var hex: UInt32 {
        switch self {
        case .sky: return 0x0593C6
        case .pink: return 0xD83995
        case .steel: return 0x4F7FAE
        case .lagoon: return 0x3AA9C9
        case .ink: return 0x12364A
        case .mint: return 0x2A9D8F
        case .amber: return 0xD9962B
        }
    }

    public var name: String { rawValue.capitalized }
}

public struct TaskList: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var name: String
    /// SF Symbol name.
    public var icon: String
    public var color: ListColor
    public var sortOrder: Double
    public var isInbox: Bool
    public var createdAt: Date

    public init(id: UUID = UUID(), name: String, icon: String, color: ListColor, sortOrder: Double,
                isInbox: Bool = false, createdAt: Date) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.sortOrder = sortOrder
        self.isInbox = isInbox
        self.createdAt = createdAt
    }

    /// Curated SF Symbols offered in the list editor (all available on iOS 17).
    public static let iconChoices = [
        "tray.fill", "briefcase.fill", "graduationcap.fill", "book.fill", "laptopcomputer",
        "person.fill", "house.fill", "cart.fill", "heart.fill", "figure.run", "paintbrush.fill",
        "music.note", "airplane", "leaf.fill", "star.fill", "lightbulb.fill"
    ]
}

// MARK: - Completion history

/// A durable record that a task (or one occurrence of a recurring task) was completed.
/// Streaks and progress are always computed from these events, never from current task state.
public struct CompletionEvent: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var taskID: UUID
    /// Snapshot so history stays readable after the task is renamed or deleted.
    public var taskTitle: String
    public var listID: UUID
    /// The occurrence day completed (the task's due day at completion; nil if undated).
    public var occurrenceDay: DayKey?
    public var completedAt: Date
    /// The local day credited, fixed at completion time. Travelling later never rewrites it.
    public var creditedDay: DayKey

    public init(id: UUID = UUID(), taskID: UUID, taskTitle: String, listID: UUID, occurrenceDay: DayKey?,
                completedAt: Date, creditedDay: DayKey) {
        self.id = id
        self.taskID = taskID
        self.taskTitle = taskTitle
        self.listID = listID
        self.occurrenceDay = occurrenceDay
        self.completedAt = completedAt
        self.creditedDay = creditedDay
    }
}

// MARK: - Settings

public struct GoalChange: Codable, Hashable, Sendable {
    public var effectiveFrom: DayKey
    public var goal: Int
    public init(effectiveFrom: DayKey, goal: Int) {
        self.effectiveFrom = effectiveFrom
        self.goal = goal
    }
}

public struct DigestSetting: Codable, Hashable, Sendable {
    public var enabled: Bool
    public var time: TimeOfDay
    public init(enabled: Bool, time: TimeOfDay) {
        self.enabled = enabled
        self.time = time
    }
}

public struct AppSettings: Codable, Hashable, Sendable {
    public static let goalRange = 1...10
    public static let defaultGoal = 3

    /// Goal history; the last entry is the current goal. Past days keep the goal in force then.
    public var goalHistory: [GoalChange]
    /// 1 = Sunday, 2 = Monday.
    public var firstWeekday: Int
    /// When a reminder on a date-only task fires.
    public var defaultReminderTime: TimeOfDay
    public var morningDigest: DigestSetting
    public var eveningDigest: DigestSetting
    public var reminderSound: Bool
    /// Haptic feedback for completions, selections and celebrations.
    public var haptics: Bool
    /// Last day the "goal reached" celebration played, so it plays once per day.
    public var lastCelebratedDay: DayKey?
    /// Optional first name for the greeting. Local only; never required.
    public var displayName: String

    public init(
        goalHistory: [GoalChange] = [GoalChange(effectiveFrom: DayKey(year: 1970, month: 1, day: 1), goal: AppSettings.defaultGoal)],
        firstWeekday: Int = 2,
        defaultReminderTime: TimeOfDay = TimeOfDay(hour: 9, minute: 0),
        morningDigest: DigestSetting = DigestSetting(enabled: false, time: TimeOfDay(hour: 8, minute: 0)),
        eveningDigest: DigestSetting = DigestSetting(enabled: false, time: TimeOfDay(hour: 20, minute: 0)),
        reminderSound: Bool = true,
        haptics: Bool = true,
        lastCelebratedDay: DayKey? = nil,
        displayName: String = ""
    ) {
        self.goalHistory = goalHistory.isEmpty
            ? [GoalChange(effectiveFrom: DayKey(year: 1970, month: 1, day: 1), goal: AppSettings.defaultGoal)]
            : goalHistory
        self.firstWeekday = firstWeekday == 1 ? 1 : 2
        self.defaultReminderTime = defaultReminderTime
        self.morningDigest = morningDigest
        self.eveningDigest = eveningDigest
        self.reminderSound = reminderSound
        self.haptics = haptics
        self.lastCelebratedDay = lastCelebratedDay
        self.displayName = String(displayName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
    }

    public var dailyGoal: Int { goalHistory.last?.goal ?? AppSettings.defaultGoal }

    enum CodingKeys: String, CodingKey {
        case goalHistory, firstWeekday, defaultReminderTime, morningDigest, eveningDigest, reminderSound, haptics, lastCelebratedDay, displayName
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppSettings()
        self.init(
            goalHistory: try c.decodeIfPresent([GoalChange].self, forKey: .goalHistory) ?? d.goalHistory,
            firstWeekday: try c.decodeIfPresent(Int.self, forKey: .firstWeekday) ?? d.firstWeekday,
            defaultReminderTime: try c.decodeIfPresent(TimeOfDay.self, forKey: .defaultReminderTime) ?? d.defaultReminderTime,
            morningDigest: try c.decodeIfPresent(DigestSetting.self, forKey: .morningDigest) ?? d.morningDigest,
            eveningDigest: try c.decodeIfPresent(DigestSetting.self, forKey: .eveningDigest) ?? d.eveningDigest,
            reminderSound: try c.decodeIfPresent(Bool.self, forKey: .reminderSound) ?? d.reminderSound,
            haptics: try c.decodeIfPresent(Bool.self, forKey: .haptics) ?? d.haptics,
            lastCelebratedDay: try c.decodeIfPresent(DayKey.self, forKey: .lastCelebratedDay),
            displayName: try c.decodeIfPresent(String.self, forKey: .displayName) ?? ""
        )
    }
}

// MARK: - Root document

public struct AppData: Codable, Hashable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var lists: [TaskList]
    public var tasks: [TaskItem]
    public var events: [CompletionEvent]
    public var settings: AppSettings

    enum CodingKeys: String, CodingKey { case schemaVersion, lists, tasks, events, settings }

    /// Tolerant decoding: documents from older builds or hand-edited backups may omit fields.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        lists = try c.decodeIfPresent([TaskList].self, forKey: .lists) ?? []
        tasks = try c.decodeIfPresent([TaskItem].self, forKey: .tasks) ?? []
        events = try c.decodeIfPresent([CompletionEvent].self, forKey: .events) ?? []
        settings = try c.decodeIfPresent(AppSettings.self, forKey: .settings) ?? AppSettings()
    }

    public init(schemaVersion: Int = AppData.currentSchemaVersion, lists: [TaskList], tasks: [TaskItem] = [],
                events: [CompletionEvent] = [], settings: AppSettings = AppSettings()) {
        self.schemaVersion = schemaVersion
        self.lists = lists
        self.tasks = tasks
        self.events = events
        self.settings = settings
    }

    /// First-launch structure: an undeletable Inbox plus three empty starter lists that
    /// match the target user (no fake tasks).
    public static func starter(now: Date) -> AppData {
        AppData(lists: [
            TaskList(name: "Inbox", icon: "tray.fill", color: .sky, sortOrder: 0, isInbox: true, createdAt: now),
            TaskList(name: "University", icon: "graduationcap.fill", color: .steel, sortOrder: 1, createdAt: now),
            TaskList(name: "Work", icon: "briefcase.fill", color: .lagoon, sortOrder: 2, createdAt: now),
            TaskList(name: "Personal", icon: "heart.fill", color: .pink, sortOrder: 3, createdAt: now)
        ])
    }

    public var inbox: TaskList {
        if let inbox = lists.first(where: \.isInbox) { return inbox }
        return lists.first ?? TaskList(name: "Inbox", icon: "tray.fill", color: .sky, sortOrder: 0, isInbox: true, createdAt: Date())
    }

    public func list(_ id: UUID) -> TaskList? { lists.first { $0.id == id } }
    public func task(_ id: UUID) -> TaskItem? { tasks.first { $0.id == id } }
}
