import XCTest
@testable import SkydayKit

final class RecurrenceTests: XCTestCase {

    func testDailyInterval() {
        let rule = RecurrenceRule(frequency: .daily, interval: 2)
        let anchor = T.day(2026, 11, 1)
        XCTAssertEqual(RecurrenceEngine.nextOccurrence(after: anchor, rule: rule, anchor: anchor), T.day(2026, 11, 3))
        XCTAssertEqual(RecurrenceEngine.nextOccurrence(after: T.day(2026, 11, 2), rule: rule, anchor: anchor), T.day(2026, 11, 3))
        XCTAssertEqual(RecurrenceEngine.latestOccurrence(onOrBefore: T.day(2026, 11, 6), rule: rule, anchor: anchor), T.day(2026, 11, 5))
        XCTAssertNil(RecurrenceEngine.latestOccurrence(onOrBefore: T.day(2026, 10, 31), rule: rule, anchor: anchor))
    }

    func testWeekdaysSkipWeekend() {
        let fri = T.day(2026, 11, 6)
        XCTAssertEqual(RecurrenceEngine.nextOccurrence(after: fri, rule: .weekdaysOnly, anchor: T.day(2026, 11, 2)), T.day(2026, 11, 9))
    }

    func testWeeklyMultipleDaysAndBiweekly() {
        let anchor = T.day(2026, 11, 2) // Monday
        let monThu = RecurrenceRule.weekly(on: [2, 5])
        let occ = RecurrenceEngine.occurrences(from: anchor, through: T.day(2026, 11, 15), rule: monThu, anchor: anchor)
        XCTAssertEqual(occ, [T.day(2026, 11, 2), T.day(2026, 11, 5), T.day(2026, 11, 9), T.day(2026, 11, 12)])

        let biweekly = RecurrenceRule(frequency: .weekly, interval: 2)
        let occ2 = RecurrenceEngine.occurrences(from: anchor, through: T.day(2026, 12, 1), rule: biweekly, anchor: anchor)
        XCTAssertEqual(occ2, [T.day(2026, 11, 2), T.day(2026, 11, 16), T.day(2026, 11, 30)])
    }

    func testMonthlyClampsToMonthEndWithoutDrifting() {
        let anchor = T.day(2026, 1, 31)
        let occ = RecurrenceEngine.occurrences(from: anchor, through: T.day(2026, 5, 31), rule: .monthly, anchor: anchor)
        XCTAssertEqual(occ, [T.day(2026, 1, 31), T.day(2026, 2, 28), T.day(2026, 3, 31), T.day(2026, 4, 30), T.day(2026, 5, 31)])
        XCTAssertEqual(RecurrenceEngine.latestOccurrence(onOrBefore: T.day(2026, 4, 29), rule: .monthly, anchor: anchor), T.day(2026, 3, 31))
    }

    func testMonthlyIntervalAcrossYearBoundary() {
        let rule = RecurrenceRule(frequency: .monthly, interval: 3)
        let anchor = T.day(2026, 11, 15)
        XCTAssertEqual(RecurrenceEngine.nextOccurrence(after: anchor, rule: rule, anchor: anchor), T.day(2027, 2, 15))
        XCTAssertEqual(RecurrenceEngine.nextOccurrence(after: T.day(2027, 2, 15), rule: rule, anchor: anchor), T.day(2027, 5, 15))
    }

    func testYearlyLeapDay() {
        let anchor = T.day(2024, 2, 29)
        XCTAssertEqual(RecurrenceEngine.nextOccurrence(after: anchor, rule: .yearly, anchor: anchor), T.day(2025, 2, 28))
        XCTAssertEqual(RecurrenceEngine.nextOccurrence(after: T.day(2027, 3, 1), rule: .yearly, anchor: anchor), T.day(2028, 2, 29))
        XCTAssertEqual(RecurrenceEngine.latestOccurrence(onOrBefore: T.day(2026, 6, 1), rule: .yearly, anchor: anchor), T.day(2026, 2, 28))
    }

    func testMatchesAgreesWithOccurrencesForManyRules() {
        let anchor = T.day(2026, 1, 30)
        let rules: [RecurrenceRule] = [.daily, RecurrenceRule(frequency: .daily, interval: 3), .weekdaysOnly,
                                       .weekly(on: [1, 4]), RecurrenceRule(frequency: .weekly, interval: 3, weekdays: [6]),
                                       .monthly, RecurrenceRule(frequency: .monthly, interval: 2), .yearly]
        for rule in rules {
            let occ = Set(RecurrenceEngine.occurrences(from: anchor, through: T.day(2027, 6, 1), rule: rule, anchor: anchor, limit: 10_000))
            var d = anchor
            while d <= T.day(2027, 6, 1) {
                XCTAssertEqual(RecurrenceEngine.matches(d, rule: rule, anchor: anchor), occ.contains(d), "\(rule.summary) \(d)")
                if let latest = RecurrenceEngine.latestOccurrence(onOrBefore: d, rule: rule, anchor: anchor) {
                    XCTAssertTrue(occ.contains(latest))
                    XCTAssertLessThanOrEqual(latest, d)
                    XCTAssertGreaterThan(RecurrenceEngine.nextOccurrence(after: latest, rule: rule, anchor: anchor), d)
                }
                d = d.adding(days: 1)
            }
        }
    }

    func testNormalizedMovesDueDayOntoSchedule() {
        // Created on a Tuesday with a Mon/Wed rule -> first occurrence is Wednesday.
        let task = TaskItem(title: "Gym", listID: UUID(), dueDay: T.day(2026, 11, 3), recurrence: .weekly(on: [2, 4]), createdAt: Date())
        let n = RecurrenceEngine.normalized(task)
        XCTAssertEqual(n.dueDay, T.day(2026, 11, 4))
        XCTAssertEqual(n.recurrenceAnchor, T.day(2026, 11, 3))
    }

    func testRollForwardSkipsMissedOccurrencesAndIsIdempotent() {
        var task = TaskItem(title: "Read", listID: UUID(), dueDay: T.day(2026, 10, 28), recurrence: .daily,
                            recurrenceAnchor: T.day(2026, 10, 1), subtasks: [Subtask(title: "a", isDone: true)], createdAt: Date())
        task = RecurrenceEngine.rolledForward(task, today: T.day(2026, 11, 3))
        XCTAssertEqual(task.dueDay, T.day(2026, 11, 3))
        XCTAssertFalse(task.subtasks[0].isDone, "a fresh occurrence starts with subtasks unchecked")
        XCTAssertEqual(RecurrenceEngine.rolledForward(task, today: T.day(2026, 11, 3)), task)

        // Weekly task missed on Monday stays overdue until the next Monday arrives.
        let weekly = TaskItem(title: "Report", listID: UUID(), dueDay: T.day(2026, 11, 2), recurrence: .weekly(),
                              recurrenceAnchor: T.day(2026, 11, 2), createdAt: Date())
        XCTAssertEqual(RecurrenceEngine.rolledForward(weekly, today: T.day(2026, 11, 4)).dueDay, T.day(2026, 11, 2))
        XCTAssertEqual(RecurrenceEngine.rolledForward(weekly, today: T.day(2026, 11, 9)).dueDay, T.day(2026, 11, 9))
    }

    func testNonRecurringNeverRolls() {
        let task = TaskItem(title: "Essay", listID: UUID(), dueDay: T.day(2026, 10, 1), createdAt: Date())
        XCTAssertEqual(RecurrenceEngine.rolledForward(task, today: T.day(2026, 11, 3)), task)
    }

    func testSummaries() {
        XCTAssertEqual(RecurrenceRule.daily.summary, "Every day")
        XCTAssertEqual(RecurrenceRule.weekdaysOnly.summary, "Every weekday")
        XCTAssertEqual(RecurrenceRule.weekly(on: [2, 5]).summary, "Every week on Mon, Thu")
        XCTAssertEqual(RecurrenceRule(frequency: .monthly, interval: 2).summary, "Every 2 months")
        XCTAssertEqual(RecurrenceRule(frequency: .daily, interval: 0).interval, 1)
    }
}
