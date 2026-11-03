import Foundation

/// Calendar-correct recurrence math on floating days.
///
/// Model: a recurring task is ONE record (the series). Its `dueDay` is the current
/// occurrence. Completing it records a `CompletionEvent` for that occurrence and moves
/// `dueDay` to the next occurrence. Because occurrences are never materialised as
/// separate task rows, relaunching the app can never create duplicates.
///
/// Missed occurrences: when the app sees a recurring task whose current occurrence is in
/// the past and a newer occurrence has arrived, it rolls forward to the latest occurrence
/// on or before today (`rolledForward`). Missed days are skipped, not stacked up.
public enum RecurrenceEngine {

    /// Does `day` fall on the rule's schedule (on or after `anchor`)?
    public static func matches(_ day: DayKey, rule: RecurrenceRule, anchor: DayKey) -> Bool {
        guard day >= anchor else { return false }
        switch rule.frequency {
        case .daily:
            return anchor.days(until: day) % rule.interval == 0
        case .weekly:
            let weekdays = effectiveWeekdays(rule: rule, anchor: anchor)
            guard weekdays.contains(day.weekday) else { return false }
            let weeks = mondayWeekIndex(day) - mondayWeekIndex(anchor)
            return weeks % rule.interval == 0
        case .monthly:
            let months = day.monthIndex - anchor.monthIndex
            guard months % rule.interval == 0 else { return false }
            return day.day == clampedDay(anchor.day, year: day.year, month: day.month)
        case .yearly:
            guard day.month == anchor.month else { return false }
            let years = day.year - anchor.year
            guard years % rule.interval == 0 else { return false }
            return day.day == clampedDay(anchor.day, year: day.year, month: day.month)
        }
    }

    /// First occurrence strictly after `day`.
    public static func nextOccurrence(after day: DayKey, rule: RecurrenceRule, anchor: DayKey) -> DayKey {
        let start = max(day.adding(days: 1), anchor)
        return firstOccurrence(onOrAfter: start, rule: rule, anchor: anchor)
    }

    /// First occurrence on or after `day`.
    public static func firstOccurrence(onOrAfter day: DayKey, rule: RecurrenceRule, anchor: DayKey) -> DayKey {
        let start = max(day, anchor)
        switch rule.frequency {
        case .daily:
            let offset = anchor.days(until: start)
            let remainder = offset % rule.interval
            return remainder == 0 ? start : start.adding(days: rule.interval - remainder)
        case .weekly:
            // At most `interval` weeks plus one week of scanning.
            var candidate = start
            for _ in 0..<(7 * (rule.interval + 1)) {
                if matches(candidate, rule: rule, anchor: anchor) { return candidate }
                candidate = candidate.adding(days: 1)
            }
            return candidate
        case .monthly:
            var monthIndex = start.monthIndex
            let phase = (monthIndex - anchor.monthIndex) % rule.interval
            if phase != 0 { monthIndex += rule.interval - phase }
            for _ in 0..<3 {
                let (y, m) = yearMonth(monthIndex)
                let candidate = DayKey(year: y, month: m, day: clampedDay(anchor.day, year: y, month: m))
                if candidate >= start { return candidate }
                monthIndex += rule.interval
            }
            let (y, m) = yearMonth(monthIndex)
            return DayKey(year: y, month: m, day: clampedDay(anchor.day, year: y, month: m))
        case .yearly:
            var year = start.year
            let phase = (year - anchor.year) % rule.interval
            if phase != 0 { year += rule.interval - phase }
            for _ in 0..<3 {
                let candidate = DayKey(year: year, month: anchor.month, day: clampedDay(anchor.day, year: year, month: anchor.month))
                if candidate >= start { return candidate }
                year += rule.interval
            }
            return DayKey(year: year, month: anchor.month, day: clampedDay(anchor.day, year: year, month: anchor.month))
        }
    }

    /// Latest occurrence on or before `day`, or nil if the series has not started.
    public static func latestOccurrence(onOrBefore day: DayKey, rule: RecurrenceRule, anchor: DayKey) -> DayKey? {
        guard day >= anchor else { return nil }
        switch rule.frequency {
        case .daily:
            let offset = anchor.days(until: day)
            return day.adding(days: -(offset % rule.interval))
        case .weekly:
            var candidate = day
            for _ in 0..<(7 * (rule.interval + 1)) {
                if candidate < anchor { return nil }
                if matches(candidate, rule: rule, anchor: anchor) { return candidate }
                candidate = candidate.adding(days: -1)
            }
            return nil
        case .monthly, .yearly:
            // Step back by whole periods from the next occurrence after `day`.
            var result: DayKey?
            var cursor = firstOccurrence(onOrAfter: anchor, rule: rule, anchor: anchor)
            if cursor > day { return nil }
            // Jump close to `day` first to keep this O(1)-ish for long-running series.
            let periodsApprox: Int
            if rule.frequency == .monthly {
                periodsApprox = max(0, (day.monthIndex - anchor.monthIndex) / rule.interval - 1)
                let (y, m) = yearMonth(anchor.monthIndex + periodsApprox * rule.interval)
                let jumped = DayKey(year: y, month: m, day: clampedDay(anchor.day, year: y, month: m))
                if jumped <= day && jumped >= anchor { cursor = jumped }
            } else {
                periodsApprox = max(0, (day.year - anchor.year) / rule.interval - 1)
                let y = anchor.year + periodsApprox * rule.interval
                let jumped = DayKey(year: y, month: anchor.month, day: clampedDay(anchor.day, year: y, month: anchor.month))
                if jumped <= day && jumped >= anchor { cursor = jumped }
            }
            while cursor <= day {
                result = cursor
                cursor = nextOccurrence(after: cursor, rule: rule, anchor: anchor)
            }
            return result
        }
    }

    /// Occurrences in [from, through], capped at `limit`.
    public static func occurrences(from: DayKey, through: DayKey, rule: RecurrenceRule, anchor: DayKey, limit: Int = 400) -> [DayKey] {
        var result: [DayKey] = []
        guard from <= through else { return result }
        var cursor = firstOccurrence(onOrAfter: from, rule: rule, anchor: anchor)
        while cursor <= through && result.count < limit {
            result.append(cursor)
            cursor = nextOccurrence(after: cursor, rule: rule, anchor: anchor)
        }
        return result
    }

    /// Normalises a recurring task so `dueDay` is a real occurrence and `anchor` is set.
    public static func normalized(_ task: TaskItem) -> TaskItem {
        guard let rule = task.recurrence else {
            var t = task
            t.recurrenceAnchor = nil
            return t
        }
        var t = task
        let due = t.dueDay ?? t.recurrenceAnchor ?? DayKey(year: 1970, month: 1, day: 1)
        let anchor = t.recurrenceAnchor ?? due
        t.recurrenceAnchor = anchor
        t.dueDay = firstOccurrence(onOrAfter: due, rule: rule, anchor: anchor)
        t.isCompleted = false
        t.completedAt = nil
        return t
    }

    /// Skip missed occurrences: move `dueDay` to the latest occurrence on or before `today`.
    /// Idempotent; returns the task unchanged when nothing needs to move.
    public static func rolledForward(_ task: TaskItem, today: DayKey) -> TaskItem {
        guard let rule = task.recurrence, let due = task.dueDay, due < today else { return task }
        let anchor = task.recurrenceAnchor ?? due
        guard let latest = latestOccurrence(onOrBefore: today, rule: rule, anchor: anchor), latest > due else { return task }
        var t = task
        t.dueDay = latest
        t.recurrenceAnchor = anchor
        t.subtasks = t.subtasks.map { Subtask(id: $0.id, title: $0.title, isDone: false) }
        t.snoozedUntil = nil
        return t
    }

    // MARK: Helpers

    static func effectiveWeekdays(rule: RecurrenceRule, anchor: DayKey) -> Set<Int> {
        rule.weekdays.isEmpty ? [anchor.weekday] : Set(rule.weekdays)
    }

    /// Week number with weeks starting Monday (used only for interval phase).
    static func mondayWeekIndex(_ day: DayKey) -> Int {
        let monday = day.startOfWeek(firstWeekday: 2)
        return floorDiv(monday.ordinal, 7)
    }

    static func clampedDay(_ day: Int, year: Int, month: Int) -> Int {
        min(day, DayKey.daysInMonth(year: year, month: month))
    }

    static func yearMonth(_ monthIndex: Int) -> (Int, Int) {
        (floorDiv(monthIndex, 12), monthIndex - floorDiv(monthIndex, 12) * 12 + 1)
    }

    static func floorDiv(_ a: Int, _ b: Int) -> Int {
        let q = a / b
        return (a % b != 0 && (a < 0) != (b < 0)) ? q - 1 : q
    }
}
