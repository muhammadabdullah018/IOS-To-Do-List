import Foundation

/// Streak policy (documented in ARCHITECTURE.md, enforced by tests):
///
/// 1. A day QUALIFIES when the number of distinct task occurrences credited to that local
///    day reaches the daily goal in force that day.
/// 2. Credit goes to the local day the task was completed (`CompletionEvent.creditedDay`),
///    not its due day. Late completions count for the day you actually did them.
/// 3. Reopening a task or undoing a completion removes its event, so credit is removed
///    from the day it was given (honest historical correction).
/// 4. Deleting a task keeps its completion events: work you did stays in history.
/// 5. Goal changes are prospective. Past days keep the goal they had. On the day of a
///    change the LOWEST goal in force at any point that day applies, so raising the goal
///    can never un-earn a day that already qualified.
/// 6. Rest day: one missed day is forgiven inside a streak if no other rest day was used in
///    the previous 6 days. Rest days keep the streak alive but do not add to its length.
/// 7. Today never breaks a streak: until midnight it is "in progress".
/// 8. Days use the device's current calendar at completion time and are stored, so travel
///    or time-zone changes never rewrite past days.
public enum StreakEngine {

    public enum DayKind: String, Sendable {
        case qualified, partial, missed, rest, today, future, beforeHistory
    }

    public struct DayStatus: Hashable, Sendable, Identifiable {
        public var day: DayKey
        public var completions: Int
        public var goal: Int
        public var kind: DayKind
        public var id: DayKey { day }
    }

    public struct Summary: Hashable, Sendable {
        public var current: Int
        public var longest: Int
        public var todayCompletions: Int
        public var todayGoal: Int
        public var todayQualified: Bool
        /// True when the live streak is currently relying on a recent rest day.
        public var restDayInUse: Bool
        public var totalCompletions: Int
        public var qualifiedDays: Int

        public var remainingToday: Int { max(0, todayGoal - todayCompletions) }
    }

    /// Distinct credited occurrences per day. Duplicate events for the same task occurrence
    /// on the same day never count twice.
    public static func completionsByDay(_ events: [CompletionEvent]) -> [DayKey: Int] {
        var seen = Set<String>()
        var counts: [DayKey: Int] = [:]
        for event in events {
            let key = "\(event.taskID.uuidString)|\(event.occurrenceDay?.description ?? "-")|\(event.creditedDay)"
            guard seen.insert(key).inserted else { continue }
            counts[event.creditedDay, default: 0] += 1
        }
        return counts
    }

    /// Goal for `day` per rule 5.
    public static func goal(for day: DayKey, history: [GoalChange]) -> Int {
        guard !history.isEmpty else { return AppSettings.defaultGoal }
        var atStart: Int?
        var sameDay: [Int] = []
        for change in history {
            if change.effectiveFrom < day { atStart = change.goal }
            else if change.effectiveFrom == day { sameDay.append(change.goal) }
        }
        let candidates = (atStart.map { [$0] } ?? []) + sameDay
        if let lowest = candidates.min() { return clampGoal(lowest) }
        // Day precedes all history: use the earliest known goal.
        return clampGoal(history.first?.goal ?? AppSettings.defaultGoal)
    }

    static func clampGoal(_ g: Int) -> Int { min(max(g, AppSettings.goalRange.lowerBound), AppSettings.goalRange.upperBound) }

    public static func summary(events: [CompletionEvent], settings: AppSettings, today: DayKey) -> Summary {
        let counts = completionsByDay(events)
        let todayGoal = goal(for: today, history: settings.goalHistory)
        let todayCount = counts[today] ?? 0
        let todayQualified = todayCount >= todayGoal
        let total = counts.values.reduce(0, +)

        guard let firstDay = counts.keys.min(), firstDay <= today else {
            return Summary(current: 0, longest: 0, todayCompletions: todayCount, todayGoal: todayGoal,
                           todayQualified: todayQualified, restDayInUse: false, totalCompletions: total, qualifiedDays: 0)
        }

        var run = 0
        var longest = 0
        var lastRest: DayKey?
        var qualifiedDays = 0
        var day = firstDay
        while day < today {
            let qualifies = (counts[day] ?? 0) >= goal(for: day, history: settings.goalHistory)
            if qualifies {
                run += 1
                qualifiedDays += 1
                longest = max(longest, run)
            } else if run > 0, lastRest.map({ $0.days(until: day) >= 7 }) ?? true {
                lastRest = day
            } else {
                run = 0
                lastRest = nil
            }
            day = day.adding(days: 1)
        }
        if todayQualified {
            run += 1
            qualifiedDays += 1
            longest = max(longest, run)
        }
        let restInUse = run > 0 && lastRest.map { $0.days(until: today) < 7 } == true
        return Summary(current: run, longest: longest, todayCompletions: todayCount, todayGoal: todayGoal,
                       todayQualified: todayQualified, restDayInUse: restInUse, totalCompletions: total,
                       qualifiedDays: qualifiedDays)
    }

    /// Per-day status for a calendar range (used by the Progress activity grid).
    public static func statuses(from: DayKey, through: DayKey, events: [CompletionEvent],
                                settings: AppSettings, today: DayKey) -> [DayStatus] {
        guard from <= through else { return [] }
        let counts = completionsByDay(events)
        let firstDay = counts.keys.min()

        // Replay the chain from history start so rest days are classified exactly as in `summary`.
        var restDays = Set<DayKey>()
        if let first = firstDay {
            var run = 0
            var lastRest: DayKey?
            var day = first
            let end = min(through, today.adding(days: -1))
            while day <= end {
                let qualifies = (counts[day] ?? 0) >= goal(for: day, history: settings.goalHistory)
                if qualifies { run += 1 }
                else if run > 0, lastRest.map({ $0.days(until: day) >= 7 }) ?? true {
                    lastRest = day
                    restDays.insert(day)
                } else { run = 0; lastRest = nil }
                day = day.adding(days: 1)
            }
        }

        var result: [DayStatus] = []
        var day = from
        while day <= through {
            let count = counts[day] ?? 0
            let g = goal(for: day, history: settings.goalHistory)
            let kind: DayKind
            if day > today { kind = .future }
            else if count >= g { kind = .qualified }
            else if day == today { kind = .today }
            else if firstDay.map({ day < $0 }) ?? true { kind = .beforeHistory }
            else if restDays.contains(day) { kind = .rest }
            else if count > 0 { kind = .partial }
            else { kind = .missed }
            result.append(DayStatus(day: day, completions: count, goal: g, kind: kind))
            day = day.adding(days: 1)
        }
        return result
    }

    /// Completions per day for the week containing `today`.
    public static func week(containing today: DayKey, events: [CompletionEvent], settings: AppSettings) -> [DayStatus] {
        let start = today.startOfWeek(firstWeekday: settings.firstWeekday)
        return statuses(from: start, through: start.adding(days: 6), events: events, settings: settings, today: today)
    }

    /// True if any full calendar week in history had every day qualified.
    public static func hasPerfectWeek(events: [CompletionEvent], settings: AppSettings, today: DayKey) -> Bool {
        let counts = completionsByDay(events)
        guard let first = counts.keys.min() else { return false }
        var weekStart = first.startOfWeek(firstWeekday: settings.firstWeekday)
        while weekStart.adding(days: 6) <= today {
            var all = true
            for offset in 0..<7 {
                let d = weekStart.adding(days: offset)
                if (counts[d] ?? 0) < goal(for: d, history: settings.goalHistory) { all = false; break }
            }
            if all { return true }
            weekStart = weekStart.adding(days: 7)
        }
        return false
    }
}
