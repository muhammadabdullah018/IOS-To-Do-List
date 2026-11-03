import Foundation
import Observation

/// Single source of truth for the app. Views read derived state and call intent methods;
/// every mutation is persisted synchronously before the call returns, then `onCommit`
/// fires so the app can re-plan notifications and refresh the widget snapshot.
@MainActor
@Observable
public final class SkydayStore {

    public struct UndoToken: Identifiable, Equatable {
        public let id = UUID()
        public let message: String
        fileprivate let snapshot: AppData
        public static func == (a: UndoToken, b: UndoToken) -> Bool { a.id == b.id }
    }

    public struct CompletionOutcome: Equatable, Sendable {
        public var didComplete: Bool
        /// True exactly once per day: the completion that first meets the daily goal.
        public var reachedDailyGoal: Bool
        public var newStreak: Int
        public static let none = CompletionOutcome(didComplete: false, reachedDailyGoal: false, newStreak: 0)
    }

    public private(set) var data: AppData
    public private(set) var pendingUndo: UndoToken?
    /// Set when saved data could not be read on launch (the file was preserved aside).
    public var recoveryNotice: String?
    public private(set) var lastSaveError: String?
    /// True if the file on disk is from a newer app version; saving is blocked to protect it.
    public private(set) var isReadOnly = false
    /// Observed day marker. `today` reads it so views re-render when the date changes even if
    /// no data changed (e.g. at midnight with no recurring tasks to roll forward).
    public private(set) var currentDay: DayKey

    /// Called after every committed change (including undo, import and day rollover).
    @ObservationIgnored public var onCommit: ((AppData) -> Void)?

    @ObservationIgnored private let persistence: DataPersisting
    @ObservationIgnored public let clock: SkydayClock

    public init(persistence: DataPersisting, clock: SkydayClock = SystemClock()) {
        self.persistence = persistence
        self.clock = clock
        let now = clock.now()
        self.currentDay = DayKey(now, calendar: clock.calendar)
        do {
            if let loaded = try persistence.load() {
                data = loaded
            } else {
                data = AppData.starter(now: now)
                try? persistence.save(data)
            }
        } catch PersistenceError.unsupportedSchema(let v) {
            data = AppData.starter(now: now)
            isReadOnly = true
            recoveryNotice = "Your saved tasks were created by a newer version of Skyday (format \(v)). Update the app to see them; nothing has been changed."
        } catch {
            data = AppData.starter(now: now)
            recoveryNotice = "Skyday couldn't read its saved data, so it started fresh. The unreadable file was kept in the app's documents folder."
            try? persistence.save(data)
        }
        rollForwardRecurring(commit: true)
    }

    // MARK: - Derived state

    public var calendar: Calendar { clock.calendar }
    public var now: Date { clock.now() }
    public var today: DayKey {
        _ = currentDay // registers an observation dependency on the day marker
        return DayKey(clock.now(), calendar: clock.calendar)
    }
    public var settings: AppSettings { data.settings }

    public var sortedLists: [TaskList] {
        data.lists.sorted { ($0.isInbox ? 0 : 1, $0.sortOrder) < ($1.isInbox ? 0 : 1, $1.sortOrder) }
    }

    public var todayOverview: TodayOverview { TaskQueries.todayOverview(data, today: today) }

    public var streak: StreakEngine.Summary {
        StreakEngine.summary(events: data.events, settings: data.settings, today: today)
    }

    public var thisWeek: [StreakEngine.DayStatus] {
        StreakEngine.week(containing: today, events: data.events, settings: data.settings)
    }

    /// The last `weeks` full calendar weeks ending with the current week.
    public func activity(weeks: Int) -> [StreakEngine.DayStatus] {
        let end = today.startOfWeek(firstWeekday: data.settings.firstWeekday).adding(days: 6)
        let start = end.adding(days: -(weeks * 7) + 1)
        return StreakEngine.statuses(from: start, through: end, events: data.events, settings: data.settings, today: today)
    }

    public var weekCompletionRate: Double? { TaskQueries.weekCompletionRate(data, today: today) }

    public var achievements: [Achievement] {
        let summary = streak
        let perfect = StreakEngine.hasPerfectWeek(events: data.events, settings: data.settings, today: today)
        return AchievementEngine.achievements(summary: summary, perfectWeek: perfect)
    }

    public func list(_ id: UUID) -> TaskList? { data.list(id) }
    public func task(_ id: UUID) -> TaskItem? { data.task(id) }
    public func openCount(listID: UUID) -> Int { TaskQueries.openCount(listID: listID, data) }

    public func tasks(in listID: UUID, sort: TaskSort) -> [TaskItem] {
        TaskQueries.sorted(TaskQueries.tasks(in: listID, data), by: sort, today: today)
    }

    public func agenda(on day: DayKey) -> [AgendaItem] { TaskQueries.agenda(data, day: day, today: today) }

    public func busyDays(from: DayKey, through: DayKey) -> Set<DayKey> { TaskQueries.busyDays(data, from: from, through: through) }

    public func search(_ query: String) -> TaskQueries.SearchResults { TaskQueries.search(query, in: data) }

    public func completions(on day: DayKey) -> [CompletionEvent] {
        data.events.filter { $0.creditedDay == day }.sorted { $0.completedAt > $1.completedAt }
    }

    public func isOverdue(_ task: TaskItem) -> Bool { task.isOverdue(today: today, now: now, calendar: calendar) }

    // MARK: - Tasks

    @discardableResult
    public func addTask(_ draft: TaskDraft) -> TaskItem? {
        guard draft.isValid else { return nil }
        let d = draft.normalized(today: today)
        let now = clock.now()
        let listID = data.list(d.listID) != nil ? d.listID : data.inbox.id
        let maxOrder = data.tasks.filter { $0.listID == listID }.map(\.sortOrder).max() ?? 0
        var task = TaskItem(title: d.title, notes: d.notes, listID: listID, priority: d.priority, dueDay: d.dueDay,
                            dueTime: d.dueTime, reminderMinutesBefore: d.reminderMinutesBefore, recurrence: d.recurrence,
                            subtasks: d.subtasks, createdAt: now, sortOrder: maxOrder + 1)
        task = RecurrenceEngine.normalized(task)
        commit(undoMessage: nil) { $0.tasks.append(task) }
        return task
    }

    public func updateTask(_ id: UUID, with draft: TaskDraft) {
        guard draft.isValid, let index = data.tasks.firstIndex(where: { $0.id == id }) else { return }
        let d = draft.normalized(today: today)
        var task = data.tasks[index]
        let scheduleChanged = task.recurrence != d.recurrence || task.dueDay != d.dueDay
        task.title = d.title
        task.notes = d.notes
        task.listID = data.list(d.listID) != nil ? d.listID : data.inbox.id
        task.priority = d.priority
        task.dueDay = d.dueDay
        task.dueTime = d.dueTime
        task.reminderMinutesBefore = d.reminderMinutesBefore
        task.recurrence = d.recurrence
        task.subtasks = d.subtasks
        task.updatedAt = clock.now()
        if scheduleChanged {
            task.recurrenceAnchor = d.recurrence == nil ? nil : d.dueDay
            task.snoozedUntil = nil
        }
        if task.recurrence != nil {
            task = RecurrenceEngine.normalized(task)
            task = skippingCompletedOccurrences(task)
        }
        commit(undoMessage: nil) { $0.tasks[index] = task }
    }

    /// Completes an open task or reopens a completed one.
    @discardableResult
    public func toggleCompletion(_ id: UUID) -> CompletionOutcome {
        guard let task = data.task(id) else { return .none }
        if task.isCompleted {
            reopen(id)
            return .none
        }
        return complete(id)
    }

    /// Idempotent completion. `expectedOccurrence` lets notification actions ignore stale
    /// requests: if the task has already moved past that occurrence nothing happens.
    @discardableResult
    public func complete(_ id: UUID, expectedOccurrence: DayKey? = nil) -> CompletionOutcome {
        guard let index = data.tasks.firstIndex(where: { $0.id == id }) else { return .none }
        let task = data.tasks[index]
        guard !task.isCompleted else { return .none }
        if let expected = expectedOccurrence, task.dueDay != expected { return .none }
        if task.isRecurring,
           data.events.contains(where: { $0.taskID == id && $0.occurrenceDay == task.dueDay && task.dueDay != nil }) {
            return .none
        }

        let now = clock.now()
        let today = self.today
        let before = StreakEngine.summary(events: data.events, settings: data.settings, today: today)
        let event = CompletionEvent(taskID: id, taskTitle: task.title, listID: task.listID, occurrenceDay: task.dueDay,
                                    completedAt: now, creditedDay: today)
        var updated = task
        updated.snoozedUntil = nil
        updated.updatedAt = now
        if let rule = task.recurrence, let due = task.dueDay {
            let anchor = task.recurrenceAnchor ?? due
            updated.recurrenceAnchor = anchor
            updated.dueDay = RecurrenceEngine.nextOccurrence(after: due, rule: rule, anchor: anchor)
            updated.subtasks = task.subtasks.map { Subtask(id: $0.id, title: $0.title, isDone: false) }
            updated = RecurrenceEngine.rolledForward(updated, today: today)
        } else {
            updated.isCompleted = true
            updated.completedAt = now
        }

        let message = task.isRecurring ? "Done. Next: \(updated.dueDay.map { RelativeDayFormatter.string(for: $0, today: today) } ?? "")" : "Completed “\(task.title)”"
        commit(undoMessage: message) { data in
            data.tasks[index] = updated
            data.events.append(event)
        }
        let after = StreakEngine.summary(events: data.events, settings: data.settings, today: today)
        var reached = false
        if !before.todayQualified && after.todayQualified && data.settings.lastCelebratedDay != today {
            reached = true
            data.settings.lastCelebratedDay = today
            persist()
        }
        return CompletionOutcome(didComplete: true, reachedDailyGoal: reached, newStreak: after.current)
    }

    /// Reopens a completed (non-recurring) task and removes the credit it earned.
    public func reopen(_ id: UUID) {
        guard let index = data.tasks.firstIndex(where: { $0.id == id }), data.tasks[index].isCompleted else { return }
        commit(undoMessage: "Reopened “\(data.tasks[index].title)”") { data in
            data.tasks[index].isCompleted = false
            data.tasks[index].completedAt = nil
            data.tasks[index].updatedAt = self.clock.now()
            data.events.removeAll { $0.taskID == id }
        }
    }

    public func deleteTask(_ id: UUID) {
        guard let task = data.task(id) else { return }
        commit(undoMessage: "Deleted “\(task.title)”") { data in
            data.tasks.removeAll { $0.id == id }
        }
    }

    public func toggleSubtask(taskID: UUID, subtaskID: UUID) {
        guard let t = data.tasks.firstIndex(where: { $0.id == taskID }),
              let s = data.tasks[t].subtasks.firstIndex(where: { $0.id == subtaskID }) else { return }
        commit(undoMessage: nil) { data in
            data.tasks[t].subtasks[s].isDone.toggle()
            data.tasks[t].updatedAt = self.clock.now()
        }
    }

    public func addSubtask(taskID: UUID, title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let t = data.tasks.firstIndex(where: { $0.id == taskID }) else { return }
        commit(undoMessage: nil) { data in
            data.tasks[t].subtasks.append(Subtask(title: trimmed))
            data.tasks[t].updatedAt = self.clock.now()
        }
    }

    public func moveTask(_ id: UUID, toList listID: UUID) {
        guard data.list(listID) != nil, let t = data.tasks.firstIndex(where: { $0.id == id }) else { return }
        let maxOrder = data.tasks.filter { $0.listID == listID }.map(\.sortOrder).max() ?? 0
        commit(undoMessage: "Moved to \(data.list(listID)?.name ?? "list")") { data in
            data.tasks[t].listID = listID
            data.tasks[t].sortOrder = maxOrder + 1
            data.tasks[t].updatedAt = self.clock.now()
        }
    }

    /// Moves a one-off task to another day (e.g. "Tomorrow" swipe). Keeps its time and reminder.
    /// Recurring tasks are not moved this way: shifting one occurrence would re-anchor the
    /// whole series. Use `skipOccurrence` (or edit the series) instead.
    public func reschedule(_ id: UUID, to day: DayKey?) {
        guard let t = data.tasks.firstIndex(where: { $0.id == id }), !data.tasks[t].isRecurring else { return }
        var task = data.tasks[t]
        task.dueDay = day
        if day == nil {
            task.dueTime = nil
            task.reminderMinutesBefore = nil
        }
        task.snoozedUntil = nil
        task.updatedAt = clock.now()
        let label = day.map { RelativeDayFormatter.string(for: $0, today: today) } ?? "Someday"
        commit(undoMessage: "Moved to \(label)") { $0.tasks[t] = task }
    }

    /// Skips the current occurrence of a recurring task without completing it (no credit).
    public func skipOccurrence(_ id: UUID) {
        guard let t = data.tasks.firstIndex(where: { $0.id == id }),
              let rule = data.tasks[t].recurrence, let due = data.tasks[t].dueDay else { return }
        var task = data.tasks[t]
        let anchor = task.recurrenceAnchor ?? due
        task.recurrenceAnchor = anchor
        task.dueDay = RecurrenceEngine.nextOccurrence(after: due, rule: rule, anchor: anchor)
        task.subtasks = task.subtasks.map { Subtask(id: $0.id, title: $0.title, isDone: false) }
        task.snoozedUntil = nil
        task.updatedAt = clock.now()
        task = skippingCompletedOccurrences(task)
        let label = task.dueDay.map { RelativeDayFormatter.string(for: $0, today: today) } ?? ""
        commit(undoMessage: "Skipped. Next: \(label)") { $0.tasks[t] = task }
    }

    /// A recurring task must never sit on an occurrence that is already completed (its
    /// checkbox would be a dead control). Advance past any such occurrences.
    private func skippingCompletedOccurrences(_ task: TaskItem) -> TaskItem {
        guard let rule = task.recurrence, var due = task.dueDay else { return task }
        let done = Set(data.events.filter { $0.taskID == task.id }.compactMap(\.occurrenceDay))
        let anchor = task.recurrenceAnchor ?? due
        var guardCount = 0
        while done.contains(due) && guardCount < 500 {
            due = RecurrenceEngine.nextOccurrence(after: due, rule: rule, anchor: anchor)
            guardCount += 1
        }
        var t = task
        t.dueDay = due
        return t
    }

    /// Persists a new manual order for the given tasks.
    public func reorder(taskIDs: [UUID]) {
        commit(undoMessage: nil) { data in
            for (position, id) in taskIDs.enumerated() {
                if let i = data.tasks.firstIndex(where: { $0.id == id }) { data.tasks[i].sortOrder = Double(position) }
            }
        }
    }

    public func snooze(_ id: UUID, minutes: Int = 60) {
        guard let t = data.tasks.firstIndex(where: { $0.id == id }) else { return }
        commit(undoMessage: nil) { $0.tasks[t].snoozedUntil = self.clock.now().addingTimeInterval(TimeInterval(minutes * 60)) }
    }

    // MARK: - Lists

    @discardableResult
    public func addList(name: String, icon: String, color: ListColor) -> TaskList? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let order = (data.lists.map(\.sortOrder).max() ?? 0) + 1
        let list = TaskList(name: String(trimmed.prefix(60)), icon: icon, color: color, sortOrder: order, createdAt: clock.now())
        commit(undoMessage: nil) { $0.lists.append(list) }
        return list
    }

    public func updateList(_ id: UUID, name: String, icon: String, color: ListColor) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let i = data.lists.firstIndex(where: { $0.id == id }) else { return }
        commit(undoMessage: nil) { data in
            data.lists[i].name = String(trimmed.prefix(60))
            data.lists[i].icon = icon
            data.lists[i].color = color
        }
    }

    /// Deletes a custom list. Its tasks move to Inbox, so nothing is lost. Inbox can't be deleted.
    public func deleteList(_ id: UUID) {
        guard let list = data.list(id), !list.isInbox else { return }
        let inboxID = data.inbox.id
        let moved = data.tasks.filter { $0.listID == id }.count
        let message = moved == 0 ? "Deleted “\(list.name)”" : "Deleted “\(list.name)”. \(moved) task\(moved == 1 ? "" : "s") moved to Inbox"
        commit(undoMessage: message) { data in
            for i in data.tasks.indices where data.tasks[i].listID == id { data.tasks[i].listID = inboxID }
            data.lists.removeAll { $0.id == id }
        }
    }

    public func reorderLists(_ ids: [UUID]) {
        commit(undoMessage: nil) { data in
            for (position, id) in ids.enumerated() {
                if let i = data.lists.firstIndex(where: { $0.id == id }), !data.lists[i].isInbox {
                    data.lists[i].sortOrder = Double(position + 1)
                }
            }
        }
    }

    // MARK: - Settings & goals

    /// Prospective goal change; see StreakEngine rule 5.
    public func setDailyGoal(_ goal: Int) {
        let clamped = StreakEngine.clampGoal(goal)
        guard clamped != data.settings.dailyGoal else { return }
        let today = self.today
        commit(undoMessage: nil) { $0.settings.goalHistory.append(GoalChange(effectiveFrom: today, goal: clamped)) }
    }

    public func updateSettings(_ change: (inout AppSettings) -> Void) {
        var s = data.settings
        change(&s)
        s.goalHistory = data.settings.goalHistory // goal changes go through setDailyGoal
        guard s != data.settings else { return }
        commit(undoMessage: nil) { $0.settings = s }
    }

    // MARK: - Lifecycle

    /// Call on foreground, day change and significant time change. Idempotent.
    public func refreshForNewDay() {
        let actual = DayKey(clock.now(), calendar: clock.calendar)
        if actual != currentDay { currentDay = actual }
        rollForwardRecurring(commit: true)
        onCommit?(data)
    }

    public func clearUndo() { pendingUndo = nil }

    public func undo() {
        guard let token = pendingUndo else { return }
        data = token.snapshot
        pendingUndo = nil
        persist()
        onCommit?(data)
    }

    public func dismissRecoveryNotice() { recoveryNotice = nil }

    // MARK: - Backup

    public func exportBackup() throws -> Data {
        let e = JSONFileStore.encoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try e.encode(data)
    }

    /// Replaces all data with a backup. Throws without changing anything if it can't be read.
    public func importBackup(_ raw: Data) throws {
        let imported = try JSONFileStore.decode(raw)
        commit(undoMessage: "Backup restored") { $0 = imported }
        rollForwardRecurring(commit: true)
    }

    /// Erases everything and returns to the first-launch state (undoable until next change).
    public func eraseAllData() {
        let fresh = AppData.starter(now: clock.now())
        commit(undoMessage: "All data erased") { $0 = fresh }
    }

    // MARK: - Internals

    private func rollForwardRecurring(commit shouldCommit: Bool) {
        let today = self.today
        var changed = false
        var tasks = data.tasks
        for i in tasks.indices {
            let rolled = RecurrenceEngine.rolledForward(tasks[i], today: today)
            if rolled != tasks[i] { tasks[i] = rolled; changed = true }
        }
        guard changed else { return }
        data.tasks = tasks
        if shouldCommit { persist() }
    }

    private func commit(undoMessage: String?, _ mutate: (inout AppData) -> Void) {
        let before = data
        var next = data
        mutate(&next)
        guard next != before else { return }
        data = next
        pendingUndo = undoMessage.map { UndoToken(message: $0, snapshot: before) }
        persist()
        onCommit?(data)
    }

    private func persist() {
        guard !isReadOnly else { return }
        do {
            try persistence.save(data)
            lastSaveError = nil
        } catch {
            lastSaveError = "Couldn't save changes: \(error.localizedDescription)"
        }
    }
}

/// "Today", "Tomorrow", "Yesterday", weekday within a week, otherwise a short date.
public enum RelativeDayFormatter {
    public static func string(for day: DayKey, today: DayKey, locale: Locale = .current) -> String {
        let diff = today.days(until: day)
        switch diff {
        case 0: return "Today"
        case 1: return "Tomorrow"
        case -1: return "Yesterday"
        default:
            var cal = Calendar(identifier: .gregorian)
            cal.timeZone = TimeZone(identifier: "UTC")!
            let date = day.noonDate(in: cal)
            let f = DateFormatter()
            f.calendar = cal
            f.timeZone = cal.timeZone
            f.locale = locale
            if diff > 1 && diff < 7 {
                f.setLocalizedDateFormatFromTemplate("EEEE")
            } else if day.year == today.year {
                f.setLocalizedDateFormatFromTemplate("MMMd")
            } else {
                f.setLocalizedDateFormatFromTemplate("yMMMd")
            }
            return f.string(from: date)
        }
    }
}
