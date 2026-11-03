import Foundation

/// Restrained, history-derived milestones. Nothing is awarded for opening the app.
public struct Achievement: Identifiable, Hashable, Sendable {
    public enum Badge: String, Sendable { case star, cloud, sun, moon, rocket, heart, check, crown }

    public var id: String
    public var title: String
    public var detail: String
    public var badge: Badge
    public var current: Int
    public var target: Int

    public var isUnlocked: Bool { current >= target }
    public var progress: Double { target == 0 ? 1 : min(1, Double(current) / Double(target)) }
}

public enum AchievementEngine {
    public static let streakMilestones = [3, 7, 14, 30, 60, 100]

    public static func achievements(summary: StreakEngine.Summary, perfectWeek: Bool) -> [Achievement] {
        let longest = summary.longest
        let total = summary.totalCompletions
        return [
            Achievement(id: "first-step", title: "First step", detail: "Complete your first task", badge: .check, current: min(total, 1), target: 1),
            Achievement(id: "warm-up", title: "Warming up", detail: "Reach a 3-day streak", badge: .sun, current: min(longest, 3), target: 3),
            Achievement(id: "consistency-star", title: "Consistency star", detail: "Reach a 7-day streak", badge: .star, current: min(longest, 7), target: 7),
            Achievement(id: "perfect-week", title: "Clear skies", detail: "Meet your goal every day of a week", badge: .cloud, current: perfectWeek ? 1 : 0, target: 1),
            Achievement(id: "fortnight", title: "Steady climb", detail: "Reach a 14-day streak", badge: .moon, current: min(longest, 14), target: 14),
            Achievement(id: "fifty-tasks", title: "Fifty finished", detail: "Complete 50 tasks", badge: .heart, current: min(total, 50), target: 50),
            Achievement(id: "sky-high", title: "Sky high", detail: "Reach a 30-day streak", badge: .rocket, current: min(longest, 30), target: 30),
            Achievement(id: "century", title: "Century", detail: "Complete 100 tasks", badge: .crown, current: min(total, 100), target: 100)
        ]
    }

    /// Next streak milestone above `current`.
    public static func nextMilestone(after current: Int) -> Int {
        streakMilestones.first { $0 > current } ?? ((current / 50) + 1) * 50
    }
}
