import XCTest
@testable import SkydayKit

final class StreakTests: XCTestCase {
    let today = T.day(2026, 11, 10)

    private func days(back offsets: [Int]) -> [DayKey] { offsets.map { today.adding(days: -$0) } }

    func testNoHistory() {
        let s = StreakEngine.summary(events: [], settings: T.settings(), today: today)
        XCTAssertEqual(s.current, 0)
        XCTAssertEqual(s.longest, 0)
        XCTAssertEqual(s.remainingToday, 3)
    }

    func testQualifiesOnlyAtGoal() {
        let s1 = StreakEngine.summary(events: T.events([today], perDay: 2), settings: T.settings(), today: today)
        XCTAssertFalse(s1.todayQualified)
        XCTAssertEqual(s1.current, 0)
        XCTAssertEqual(s1.remainingToday, 1)
        let s2 = StreakEngine.summary(events: T.events([today], perDay: 3), settings: T.settings(), today: today)
        XCTAssertTrue(s2.todayQualified)
        XCTAssertEqual(s2.current, 1)
    }

    func testTodayInProgressDoesNotBreakStreak() {
        let events = T.events(days(back: [1, 2, 3]), perDay: 3)
        let s = StreakEngine.summary(events: events, settings: T.settings(), today: today)
        XCTAssertEqual(s.current, 3)
        XCTAssertFalse(s.todayQualified)
        let s2 = StreakEngine.summary(events: events + T.events([today], perDay: 3), settings: T.settings(), today: today)
        XCTAssertEqual(s2.current, 4)
    }

    func testDuplicateEventsForSameOccurrenceCountOnce() {
        let task = UUID()
        let occ = T.day(2026, 11, 10)
        let dupes = (0..<5).map { _ in T.event(today, task: task, occurrence: occ) }
        XCTAssertEqual(StreakEngine.completionsByDay(dupes)[today], 1)
    }

    func testSingleRestDayKeepsStreakButDoesNotCount() {
        // Qualified 1,2 days ago; missed 3; qualified 4,5,6.
        let events = T.events(days(back: [1, 2, 4, 5, 6]), perDay: 3)
        let s = StreakEngine.summary(events: events, settings: T.settings(), today: today)
        XCTAssertEqual(s.current, 5, "rest day keeps the chain but adds nothing")
        XCTAssertTrue(s.restDayInUse)
    }

    func testTwoConsecutiveMissedDaysBreakStreak() {
        let events = T.events(days(back: [1, 2, 5, 6]), perDay: 3) // missed 3 and 4
        let s = StreakEngine.summary(events: events, settings: T.settings(), today: today)
        XCTAssertEqual(s.current, 2)
        XCTAssertEqual(s.longest, 2)
    }

    func testTwoRestDaysWithinAWeekBreakStreak() {
        // Missed 2 and 5 days ago (3 days apart) -> second miss breaks.
        let events = T.events(days(back: [1, 3, 4, 6, 7]), perDay: 3)
        let s = StreakEngine.summary(events: events, settings: T.settings(), today: today)
        // Forward: -7,-6 Q; -5 rest; -4,-3 Q; -2 second miss within 7 days -> break; -1 Q.
        XCTAssertEqual(s.current, 1)
        XCTAssertEqual(s.longest, 4)
    }

    func testRestDaysSevenDaysApartAreAllowed() {
        // Missed 2 and 9 days ago.
        let qualified = (1...12).filter { $0 != 2 && $0 != 9 }
        let events = T.events(days(back: qualified), perDay: 3)
        let s = StreakEngine.summary(events: events, settings: T.settings(), today: today)
        XCTAssertEqual(s.current, 10)
    }

    func testYesterdayRestKeepsStreakAliveAndFlagsIt() {
        let events = T.events(days(back: [2, 3, 4]), perDay: 3)
        let s = StreakEngine.summary(events: events, settings: T.settings(), today: today)
        XCTAssertEqual(s.current, 3)
        XCTAssertTrue(s.restDayInUse)
    }

    func testLongestStreakAcrossHistory() {
        let events = T.events(days(back: [30, 29, 28, 27, 26, 25, 24, 10, 9]), perDay: 3)
        let s = StreakEngine.summary(events: events, settings: T.settings(), today: today)
        XCTAssertEqual(s.longest, 7)
        XCTAssertEqual(s.current, 0)
    }

    func testGoalChangeIsProspective() {
        // Goal 3 historically; on day -2 user raised to 5. Days -5...-3 had 3 each (qualified under old goal).
        var settings = T.settings(goal: 3)
        settings.goalHistory.append(GoalChange(effectiveFrom: today.adding(days: -2), goal: 5))
        let events = T.events(days(back: [3, 4, 5]), perDay: 3) + T.events(days(back: [1, 2]), perDay: 4)
        let s = StreakEngine.summary(events: events, settings: settings, today: today)
        // Day -2: lowest goal in force that day is min(3, 5) = 3 -> qualifies with 4.
        // Day -1: goal 5 -> 4 completions do not qualify -> rest day.
        XCTAssertEqual(s.current, 4)
        XCTAssertEqual(StreakEngine.goal(for: today.adding(days: -5), history: settings.goalHistory), 3)
        XCTAssertEqual(StreakEngine.goal(for: today.adding(days: -2), history: settings.goalHistory), 3)
        XCTAssertEqual(StreakEngine.goal(for: today, history: settings.goalHistory), 5)
    }

    func testRaisingGoalLaterTodayCannotUnearnToday() {
        var settings = T.settings(goal: 3)
        let events = T.events([today], perDay: 3)
        XCTAssertTrue(StreakEngine.summary(events: events, settings: settings, today: today).todayQualified)
        settings.goalHistory.append(GoalChange(effectiveFrom: today, goal: 6))
        XCTAssertTrue(StreakEngine.summary(events: events, settings: settings, today: today).todayQualified)
        // Tomorrow the new goal applies.
        XCTAssertEqual(StreakEngine.goal(for: today.adding(days: 1), history: settings.goalHistory), 6)
    }

    func testCreditUsesStoredDayNotTimeZoneOfViewer() {
        // Completed at 23:30 in New York: credited 2026-11-09 even though it is 04:30 on the 10th in London.
        let ny = T.calendar()
        let instant = T.date(2026, 11, 9, 23, 30)
        let event = CompletionEvent(taskID: UUID(), taskTitle: "x", listID: UUID(), occurrenceDay: nil,
                                    completedAt: instant, creditedDay: DayKey(instant, calendar: ny))
        XCTAssertEqual(event.creditedDay, T.day(2026, 11, 9))
        let counts = StreakEngine.completionsByDay([event])
        XCTAssertEqual(counts[T.day(2026, 11, 9)], 1)
        XCTAssertNil(counts[T.day(2026, 11, 10)])
    }

    func testStatusesClassifyDays() {
        let events = T.events(days(back: [1, 3, 4]), perDay: 3) + T.events(days(back: [5]), perDay: 1)
        let statuses = StreakEngine.statuses(from: today.adding(days: -6), through: today.adding(days: 1),
                                             events: events, settings: T.settings(), today: today)
        let kinds = statuses.map(\.kind)
        XCTAssertEqual(kinds, [.beforeHistory, .partial, .qualified, .qualified, .rest, .qualified, .today, .future])
    }

    func testPerfectWeek() {
        let settings = T.settings(goal: 1)
        let monday = today.startOfWeek(firstWeekday: 2).adding(days: -7)
        let full = (0..<7).map { monday.adding(days: $0) }
        XCTAssertTrue(StreakEngine.hasPerfectWeek(events: T.events(full, perDay: 1), settings: settings, today: today))
        XCTAssertFalse(StreakEngine.hasPerfectWeek(events: T.events(Array(full.dropLast()), perDay: 1), settings: settings, today: today))
    }

    func testAchievementsAndMilestones() {
        let events = T.events(days(back: Array(0...6)), perDay: 3)
        let summary = StreakEngine.summary(events: events, settings: T.settings(), today: today)
        let list = AchievementEngine.achievements(summary: summary, perfectWeek: false)
        XCTAssertTrue(list.first { $0.id == "consistency-star" }!.isUnlocked)
        XCTAssertFalse(list.first { $0.id == "fortnight" }!.isUnlocked)
        XCTAssertEqual(list.first { $0.id == "fifty-tasks" }!.current, 21)
        XCTAssertEqual(AchievementEngine.nextMilestone(after: 7), 14)
        XCTAssertEqual(AchievementEngine.nextMilestone(after: 100), 150)
    }

    func testLongHistoryPerformance() {
        let events = T.events((0..<730).map { today.adding(days: -$0) }, perDay: 3)
        measure { _ = StreakEngine.summary(events: events, settings: T.settings(), today: today) }
    }
}
