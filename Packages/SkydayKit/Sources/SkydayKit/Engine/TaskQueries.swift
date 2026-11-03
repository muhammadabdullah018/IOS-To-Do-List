import Foundation

/// A task as it appears on a particular day. Recurring tasks are projected onto future
/// days for planning views; projections are read-only views, never stored rows.
public struct AgendaItem: Identifiable, Hashable, Sendable {
    public var task: TaskItem
    public var day: DayKey
    /// True when this is a future occurrence of a recurring task (not the current one).
    public var isProjection: Bool
    public var id: String { "\(task.id.uuidString)|\(day)" }
}

public struct TodayOverview: Hashable, Sendable {
    public var overdue: [TaskItem]
    public var dueToday: [TaskItem]
    /// The first three actionable tasks, in "do this next" order.
    public var upNext: [TaskItem]
    /// Incomplete tasks due in the next 7 days (excluding today).
    public var comingUp: [TaskItem]
    public var completedToday: [CompletionEvent]

    public var openCount: Int { overdue.count + dueToday.count }
    public var doneCount: Int { completedToday.count }
    public var plannedCount: Int { openCount + doneCount }
    public var fraction: Double { plannedCount == 0 ? 0 : Double(doneCount) / Double(plannedCount) }
    public var allActionable: [TaskItem] { overdue + dueToday }
}

public enum TaskSort: String, CaseIterable, Codable, Sendable, Identifiable {
    case smart, dueDate, priority, title, manual
    public var id: String { rawValue }
    public var label: String {
        switch self {
        case .smart: return "Smart"
        case .dueDate: return "Due date"
        case .priority: return "Priority"
        case .title: return "Title"
        case .manual: return "Manual"
        }
    }
}

public enum TaskQueries {

    /// "Do next" order: overdue first (oldest first), then priority (high first),
    /// then due time (timed before untimed), then manual order, then creation.
    public static func actionOrder(_ a: TaskItem, _ b: TaskItem, today: DayKey) -> Bool {
        let aOver = (a.dueDay ?? today) < today
        let bOver = (b.dueDay ?? today) < today
        if aOver != bOver { return aOver }
        if aOver, let ad = a.dueDay, let bd = b.dueDay, ad != bd { return ad < bd }
        if a.priority != b.priority { return a.priority > b.priority }
        switch (a.dueTime, b.dueTime) {
        case let (at?, bt?) where at != bt: return at < bt
        case (.some, .none): return true
        case (.none, .some): return false
        default: break
        }
        if a.sortOrder != b.sortOrder { return a.sortOrder < b.sortOrder }
        return a.createdAt < b.createdAt
    }

    public static func todayOverview(_ data: AppData, today: DayKey) -> TodayOverview {
        var overdue: [TaskItem] = []
        var dueToday: [TaskItem] = []
        var comingUp: [TaskItem] = []
        let horizon = today.adding(days: 7)
        for task in data.tasks where !task.isCompleted {
            guard let due = task.dueDay else { continue }
            if due < today { overdue.append(task) }
            else if due == today { dueToday.append(task) }
            else if due <= horizon { comingUp.append(task) }
        }
        overdue.sort { actionOrder($0, $1, today: today) }
        dueToday.sort { actionOrder($0, $1, today: today) }
        comingUp.sort {
            if $0.dueDay != $1.dueDay { return ($0.dueDay ?? today) < ($1.dueDay ?? today) }
            return actionOrder($0, $1, today: today)
        }
        let upNext = Array((overdue + dueToday).prefix(3))
        let completed = data.events
            .filter { $0.creditedDay == today }
            .sorted { $0.completedAt > $1.completedAt }
        return TodayOverview(overdue: overdue, dueToday: dueToday, upNext: upNext,
                             comingUp: Array(comingUp.prefix(5)), completedToday: completed)
    }

    /// Everything relevant to `day`: current occurrences due that day, projected recurring
    /// occurrences, and (for today) overdue tasks.
    public static func agenda(_ data: AppData, day: DayKey, today: DayKey) -> [AgendaItem] {
        var items: [AgendaItem] = []
        for task in data.tasks where !task.isCompleted {
            guard let due = task.dueDay else { continue }
            if due == day || (day == today && due < today) {
                items.append(AgendaItem(task: task, day: due, isProjection: false))
            } else if let rule = task.recurrence, day > due,
                      RecurrenceEngine.matches(day, rule: rule, anchor: task.recurrenceAnchor ?? due) {
                items.append(AgendaItem(task: task, day: day, isProjection: true))
            }
        }
        return items.sorted { actionOrder($0.task, $1.task, today: today) }
    }

    /// Days in [from, through] that have at least one scheduled item (for calendar dots).
    public static func busyDays(_ data: AppData, from: DayKey, through: DayKey) -> Set<DayKey> {
        var days = Set<DayKey>()
        for task in data.tasks where !task.isCompleted {
            guard let due = task.dueDay else { continue }
            if let rule = task.recurrence {
                for d in RecurrenceEngine.occurrences(from: max(from, due), through: through, rule: rule,
                                                      anchor: task.recurrenceAnchor ?? due, limit: 60) {
                    days.insert(d)
                }
            } else if due >= from && due <= through {
                days.insert(due)
            }
        }
        return days
    }

    public static func tasks(in listID: UUID, _ data: AppData, includeCompleted: Bool = true) -> [TaskItem] {
        data.tasks.filter { $0.listID == listID && (includeCompleted || !$0.isCompleted) }
    }

    public static func openCount(listID: UUID, _ data: AppData) -> Int {
        data.tasks.reduce(0) { $0 + (($1.listID == listID && !$1.isCompleted) ? 1 : 0) }
    }

    public static func sorted(_ tasks: [TaskItem], by sort: TaskSort, today: DayKey) -> [TaskItem] {
        switch sort {
        case .smart:
            return tasks.sorted {
                switch ($0.dueDay, $1.dueDay) {
                case let (a?, b?) where a != b: return a < b
                case (.some, .none): return true
                case (.none, .some): return false
                default: return actionOrder($0, $1, today: today)
                }
            }
        case .dueDate:
            // Undated last; on the same day timed tasks sort by time, untimed at end of day.
            func key(_ t: TaskItem) -> Int {
                guard let day = t.dueDay else { return Int.max }
                return day.ordinal * 1440 + (t.dueTime?.minutesSinceMidnight ?? 1439)
            }
            return tasks.sorted {
                let a = key($0), b = key($1)
                if a != b { return a < b }
                return $0.createdAt < $1.createdAt
            }
        case .priority:
            return tasks.sorted {
                if $0.priority != $1.priority { return $0.priority > $1.priority }
                return actionOrder($0, $1, today: today)
            }
        case .title:
            return tasks.sorted { $0.title.localizedStandardCompare($1.title) == .orderedAscending }
        case .manual:
            return tasks.sorted {
                if $0.sortOrder != $1.sortOrder { return $0.sortOrder < $1.sortOrder }
                return $0.createdAt < $1.createdAt
            }
        }
    }

    /// Share of this week's work that is done: completions credited this week divided by
    /// (those completions + still-open tasks due between the week start and today).
    /// nil when nothing was due or done yet this week (show "–", never a fake 0% or 100%).
    public static func weekCompletionRate(_ data: AppData, today: DayKey) -> Double? {
        let start = today.startOfWeek(firstWeekday: data.settings.firstWeekday)
        let done = data.events.filter { $0.creditedDay >= start && $0.creditedDay <= today }.count
        let open = data.tasks.filter { t in
            guard !t.isCompleted, let due = t.dueDay else { return false }
            return due >= start && due <= today
        }.count
        let total = done + open
        return total == 0 ? nil : Double(done) / Double(total)
    }

    public struct SearchResults: Hashable, Sendable {
        public var lists: [TaskList]
        public var tasks: [TaskItem]
        public var isEmpty: Bool { lists.isEmpty && tasks.isEmpty }
    }

    /// Case- and diacritic-insensitive search over list names, task titles, notes and subtasks.
    public static func search(_ query: String, in data: AppData) -> SearchResults {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return SearchResults(lists: [], tasks: []) }
        func hit(_ s: String) -> Bool { s.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        let lists = data.lists.filter { hit($0.name) }.sorted { $0.sortOrder < $1.sortOrder }
        let tasks = data.tasks.filter { t in
            hit(t.title) || hit(t.notes) || t.subtasks.contains { hit($0.title) }
        }.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            return $0.updatedAt > $1.updatedAt
        }
        return SearchResults(lists: lists, tasks: tasks)
    }
}
