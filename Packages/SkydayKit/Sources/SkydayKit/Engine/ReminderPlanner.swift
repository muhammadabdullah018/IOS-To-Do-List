import Foundation

/// A local notification Skyday wants pending. IDs are stable and derived from the task and
/// occurrence, so re-planning is idempotent: same data in, same requests out.
public struct PlannedNotification: Hashable, Sendable, Identifiable {
    public enum Kind: String, Hashable, Sendable { case task, snooze, morningDigest, eveningDigest }

    public var id: String
    public var kind: Kind
    public var taskID: UUID?
    public var title: String
    public var body: String
    public var fireDate: Date

    public init(id: String, kind: Kind, taskID: UUID?, title: String, body: String, fireDate: Date) {
        self.id = id
        self.kind = kind
        self.taskID = taskID
        self.title = title
        self.body = body
        self.fireDate = fireDate
    }

    /// Identity of the request content used for diffing against what iOS already has pending.
    public var fingerprint: String { "\(title)|\(body)|\(Int(fireDate.timeIntervalSince1970))" }
}

/// What is currently pending in UNUserNotificationCenter, reduced to diffable data.
public struct PendingNotification: Hashable, Sendable {
    public var id: String
    public var fingerprint: String
    public init(id: String, fingerprint: String) {
        self.id = id
        self.fingerprint = fingerprint
    }
}

public enum ReminderPlanner {
    /// iOS keeps at most 64 pending local notifications per app; extra requests are dropped
    /// silently by the system, so Skyday plans within this budget, soonest first.
    public static let systemPendingLimit = 64
    /// Days ahead to plan digests and recurring occurrences. Re-planned on every app run and
    /// data change, so a short horizon is enough.
    public static let horizonDays = 7
    public static let recurringOccurrencesAhead = 3
    public static let idPrefix = "skyday."

    public static func taskRequestID(_ taskID: UUID, _ day: DayKey) -> String { "\(idPrefix)task.\(taskID.uuidString).\(day)" }
    public static func snoozeRequestID(_ taskID: UUID) -> String { "\(idPrefix)snooze.\(taskID.uuidString)" }
    public static func digestRequestID(_ kind: PlannedNotification.Kind, _ day: DayKey) -> String { "\(idPrefix)\(kind.rawValue).\(day)" }

    /// Fire date of a task reminder for an occurrence `day`.
    public static func fireDate(for task: TaskItem, on day: DayKey, settings: AppSettings, calendar: Calendar) -> Date? {
        guard let minutes = task.reminderMinutesBefore else { return nil }
        if let time = task.dueTime {
            return day.date(at: time, in: calendar).addingTimeInterval(TimeInterval(-max(0, minutes) * 60))
        }
        return day.date(at: settings.defaultReminderTime, in: calendar)
    }

    public static func plan(_ data: AppData, now: Date, calendar: Calendar) -> [PlannedNotification] {
        let today = DayKey(now, calendar: calendar)
        let horizon = today.adding(days: horizonDays)
        var result: [PlannedNotification] = []
        let listNames = Dictionary(uniqueKeysWithValues: data.lists.map { ($0.id, $0.name) })

        for task in data.tasks where !task.isCompleted {
            if let snooze = task.snoozedUntil, snooze > now {
                result.append(PlannedNotification(
                    id: snoozeRequestID(task.id), kind: .snooze, taskID: task.id,
                    title: task.title, body: "Reminder · \(listNames[task.listID] ?? "Skyday")", fireDate: snooze))
            }
            guard task.reminderMinutesBefore != nil, let due = task.dueDay else { continue }
            var days = [due]
            if let rule = task.recurrence {
                let anchor = task.recurrenceAnchor ?? due
                var cursor = due
                for _ in 0..<recurringOccurrencesAhead {
                    cursor = RecurrenceEngine.nextOccurrence(after: cursor, rule: rule, anchor: anchor)
                    if cursor > horizon { break }
                    days.append(cursor)
                }
            }
            for day in days {
                guard let fire = fireDate(for: task, on: day, settings: data.settings, calendar: calendar), fire > now else { continue }
                result.append(PlannedNotification(
                    id: taskRequestID(task.id, day), kind: .task, taskID: task.id,
                    title: task.title, body: reminderBody(task, day: day, listName: listNames[task.listID], calendar: calendar),
                    fireDate: fire))
            }
        }

        result += digests(data, today: today, now: now, calendar: calendar)
        result.sort { $0.fireDate == $1.fireDate ? $0.id < $1.id : $0.fireDate < $1.fireDate }
        return Array(result.prefix(systemPendingLimit))
    }

    static func reminderBody(_ task: TaskItem, day: DayKey, listName: String?, calendar: Calendar) -> String {
        var parts: [String] = []
        if let time = task.dueTime {
            let date = day.date(at: time, in: calendar)
            let f = DateFormatter()
            f.calendar = calendar
            f.timeZone = calendar.timeZone
            f.locale = calendar.locale ?? Locale.current
            f.dateStyle = .none
            f.timeStyle = .short
            parts.append("Due \(f.string(from: date))")
        } else {
            parts.append("Due today")
        }
        if let listName { parts.append(listName) }
        return parts.joined(separator: " · ")
    }

    /// Morning: what is planned for that day. Evening: what is still open that day.
    /// Content is computed from stored data; because Skyday re-plans on every change, the
    /// counts are accurate unless tasks change on another device (not supported in v1).
    static func digests(_ data: AppData, today: DayKey, now: Date, calendar: Calendar) -> [PlannedNotification] {
        let s = data.settings
        guard s.morningDigest.enabled || s.eveningDigest.enabled else { return [] }
        var result: [PlannedNotification] = []
        for offset in 0..<horizonDays {
            let day = today.adding(days: offset)
            let planned = plannedTasks(data, on: day, today: today)
            guard !planned.isEmpty else { continue }
            if s.morningDigest.enabled {
                let fire = day.date(at: s.morningDigest.time, in: calendar)
                if fire > now {
                    let first = planned[0].title
                    let body = planned.count == 1 ? "One task today: \(first)" : "\(planned.count) tasks today. First up: \(first)"
                    result.append(PlannedNotification(id: digestRequestID(.morningDigest, day), kind: .morningDigest, taskID: nil,
                                                      title: "Good morning", body: body, fireDate: fire))
                }
            }
            if s.eveningDigest.enabled {
                let fire = day.date(at: s.eveningDigest.time, in: calendar)
                if fire > now {
                    let body = planned.count == 1 ? "1 task is still open. Finish it or move it to tomorrow." : "\(planned.count) tasks are still open. Pick one to finish or move the rest."
                    result.append(PlannedNotification(id: digestRequestID(.eveningDigest, day), kind: .eveningDigest, taskID: nil,
                                                      title: "Evening check-in", body: body, fireDate: fire))
                }
            }
        }
        return result
    }

    /// Incomplete tasks that will be actionable on `day` if nothing changes before then:
    /// due that day (including recurring occurrences) plus non-recurring carry-overs.
    static func plannedTasks(_ data: AppData, on day: DayKey, today: DayKey) -> [TaskItem] {
        data.tasks.filter { task in
            guard !task.isCompleted, let due = task.dueDay else { return false }
            if due == day { return true }
            if let rule = task.recurrence {
                return day > due && RecurrenceEngine.matches(day, rule: rule, anchor: task.recurrenceAnchor ?? due)
            }
            return due < day
        }.sorted { TaskQueries.actionOrder($0, $1, today: day) }
    }

    /// Minimal change set to move iOS from `pending` to `desired`. Only Skyday-owned IDs are
    /// ever removed.
    /// `fingerprintSuffix` carries delivery options that are not part of the planned content
    /// (e.g. the sound setting), so toggling them replaces pending requests too.
    public static func diff(pending: [PendingNotification], desired: [PlannedNotification],
                            fingerprintSuffix: String = "") -> (remove: [String], add: [PlannedNotification]) {
        let desiredByID = Dictionary(desired.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        var remove: [String] = []
        var pendingByID: [String: String] = [:]
        for p in pending where p.id.hasPrefix(idPrefix) {
            pendingByID[p.id] = p.fingerprint
            if let want = desiredByID[p.id] {
                if want.fingerprint + fingerprintSuffix != p.fingerprint { remove.append(p.id) }
            } else {
                remove.append(p.id)
            }
        }
        let add = desired.filter { pendingByID[$0.id] != $0.fingerprint + fingerprintSuffix }
        return (remove.sorted(), add)
    }
}
