import XCTest
@testable import SkydayKit

final class DayKeyTests: XCTestCase {

    func testOrdinalRoundTripAndWeekdayMatchFoundation() {
        let cal = T.calendar("UTC")
        var day = T.day(1999, 12, 25)
        for _ in 0..<12_000 { // ~33 years, covers leap and century rules around 2000
            XCTAssertEqual(DayKey(ordinal: day.ordinal), day)
            let date = day.noonDate(in: cal)
            XCTAssertEqual(DayKey(date, calendar: cal), day)
            XCTAssertEqual(cal.component(.weekday, from: date), day.weekday, "weekday mismatch on \(day)")
            day = day.adding(days: 1)
        }
    }

    func testKnownValues() {
        XCTAssertEqual(T.day(1970, 1, 1).ordinal, 0)
        XCTAssertEqual(T.day(1970, 1, 1).weekday, 5) // Thursday
        XCTAssertEqual(T.day(2026, 11, 3).weekday, 3) // Tuesday
        XCTAssertEqual(T.day(2024, 2, 28).adding(days: 1), T.day(2024, 2, 29))
        XCTAssertEqual(T.day(2026, 2, 28).adding(days: 1), T.day(2026, 3, 1))
        XCTAssertEqual(T.day(2026, 12, 31).adding(days: 1), T.day(2027, 1, 1))
        XCTAssertEqual(T.day(2026, 1, 1).days(until: T.day(2027, 1, 1)), 365)
        XCTAssertFalse(DayKey.isLeapYear(2100))
        XCTAssertTrue(DayKey.isLeapYear(2000))
    }

    func testStartOfWeek() {
        let tue = T.day(2026, 11, 3)
        XCTAssertEqual(tue.startOfWeek(firstWeekday: 2), T.day(2026, 11, 2)) // Monday
        XCTAssertEqual(tue.startOfWeek(firstWeekday: 1), T.day(2026, 11, 1)) // Sunday
        let sun = T.day(2026, 11, 8)
        XCTAssertEqual(sun.startOfWeek(firstWeekday: 2), T.day(2026, 11, 2))
        XCTAssertEqual(sun.startOfWeek(firstWeekday: 1), sun)
    }

    func testCodableAsISODayString() throws {
        let data = try JSONEncoder().encode([T.day(2026, 3, 8)])
        XCTAssertEqual(String(data: data, encoding: .utf8), "[\"2026-03-08\"]")
        XCTAssertEqual(try JSONDecoder().decode([DayKey].self, from: data), [T.day(2026, 3, 8)])
        XCTAssertNil(DayKey(string: "2026-02-30"))
        XCTAssertNil(DayKey(string: "garbage"))
        XCTAssertThrowsError(try JSONDecoder().decode([DayKey].self, from: Data("[\"2026-13-01\"]".utf8)))
    }

    func testDSTSpringForwardGapResolvesForward() {
        // 2026-03-08 02:30 does not exist in New York.
        let cal = T.calendar()
        let day = T.day(2026, 3, 8)
        let date = day.date(at: TimeOfDay(hour: 2, minute: 30), in: cal)
        XCTAssertEqual(DayKey(date, calendar: cal), day)
        XCTAssertEqual(cal.component(.hour, from: date), 3)
        // Day length is 23h but day arithmetic is unaffected.
        XCTAssertEqual(day.adding(days: 1), T.day(2026, 3, 9))
        XCTAssertEqual(day.startDate(in: cal), cal.startOfDay(for: T.date(2026, 3, 8, 12)))
    }

    func testDSTFallBackKeepsWallClockTime() {
        let cal = T.calendar()
        let nine = TimeOfDay(hour: 9, minute: 0)
        let before = T.day(2026, 10, 31).date(at: nine, in: cal)
        let after = T.day(2026, 11, 1).date(at: nine, in: cal)
        XCTAssertEqual(after.timeIntervalSince(before), 25 * 3600) // 25-hour day, still 9:00 local
        XCTAssertEqual(cal.component(.hour, from: after), 9)
    }

    func testSameInstantIsDifferentDayInDifferentZones() {
        let instant = T.date(2026, 11, 3, 22, 30) // 22:30 New York = 03:30 next day London
        XCTAssertEqual(DayKey(instant, calendar: T.calendar()), T.day(2026, 11, 3))
        XCTAssertEqual(DayKey(instant, calendar: T.calendar("Europe/London")), T.day(2026, 11, 4))
    }

    func testTimeOfDayClampsAndCodes() throws {
        XCTAssertEqual(TimeOfDay(hour: 25, minute: -3), TimeOfDay(hour: 23, minute: 0))
        let data = try JSONEncoder().encode([TimeOfDay(hour: 7, minute: 5)])
        XCTAssertEqual(String(data: data, encoding: .utf8), "[\"07:05\"]")
    }
}
