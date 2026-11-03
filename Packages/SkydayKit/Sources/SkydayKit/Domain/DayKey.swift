import Foundation

/// A local calendar day ("floating" date) such as 2026-11-03.
///
/// Skyday stores due dates as calendar days rather than absolute instants, the same
/// way Apple Reminders treats all-day items: a task due "Tuesday" stays due on Tuesday
/// when the user travels to another time zone. All day arithmetic is pure integer math
/// on a proleptic Gregorian day ordinal, so it is immune to DST gaps and repeated hours.
public struct DayKey: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let year: Int
    public let month: Int
    public let day: Int

    public init(year: Int, month: Int, day: Int) {
        precondition((1...12).contains(month), "month out of range")
        precondition(day >= 1 && day <= DayKey.daysInMonth(year: year, month: month), "day out of range")
        self.year = year
        self.month = month
        self.day = day
    }

    /// The local day containing `date` in `calendar`'s time zone.
    public init(_ date: Date, calendar: Calendar) {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: c.year ?? 1970, month: c.month ?? 1, day: c.day ?? 1)
    }

    /// Days since 1970-01-01 (may be negative). Howard Hinnant's days_from_civil.
    public var ordinal: Int {
        let y = month <= 2 ? year - 1 : year
        let era = (y >= 0 ? y : y - 399) / 400
        let yoe = y - era * 400
        let mp = (month + 9) % 12
        let doy = (153 * mp + 2) / 5 + day - 1
        let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy
        return era * 146_097 + doe - 719_468
    }

    public init(ordinal: Int) {
        let z = ordinal + 719_468
        let era = (z >= 0 ? z : z - 146_096) / 146_097
        let doe = z - era * 146_097
        let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365
        let doy = doe - (365 * yoe + yoe / 4 - yoe / 100)
        let mp = (5 * doy + 2) / 153
        let d = doy - (153 * mp + 2) / 5 + 1
        let m = mp < 10 ? mp + 3 : mp - 9
        let y = yoe + era * 400 + (m <= 2 ? 1 : 0)
        self.init(year: y, month: m, day: d)
    }

    public func adding(days: Int) -> DayKey { DayKey(ordinal: ordinal + days) }

    /// Whole days from `self` to `other` (positive when `other` is later).
    public func days(until other: DayKey) -> Int { other.ordinal - ordinal }

    /// Gregorian weekday, 1 = Sunday ... 7 = Saturday (matches `Calendar.component(.weekday)`).
    public var weekday: Int {
        // 1970-01-01 was a Thursday (weekday 5).
        let w = (ordinal + 4) % 7
        return (w < 0 ? w + 7 : w) + 1
    }

    /// Same day `months` later, clamped to the target month's length (Jan 31 + 1 = Feb 28/29).
    public func addingMonths(_ months: Int) -> DayKey {
        let index = monthIndex + months
        let y = Int((Double(index) / 12).rounded(.down))
        let m = index - y * 12 + 1
        return DayKey(year: y, month: m, day: min(day, DayKey.daysInMonth(year: y, month: m)))
    }

    /// Month index since year 0, used for monthly recurrence intervals.
    public var monthIndex: Int { year * 12 + (month - 1) }

    /// The first day of the week containing `self`, for a week starting on `firstWeekday` (1 = Sunday, 2 = Monday).
    public func startOfWeek(firstWeekday: Int) -> DayKey {
        let back = (weekday - firstWeekday + 7) % 7
        return adding(days: -back)
    }

    /// Start of this day in `calendar`'s time zone. Computed from local noon so days whose
    /// midnight does not exist (DST at 00:00 in some zones) still resolve correctly.
    public func startDate(in calendar: Calendar) -> Date {
        calendar.startOfDay(for: noonDate(in: calendar))
    }

    /// Local noon of this day; noon always exists, which makes it a safe anchor.
    public func noonDate(in calendar: Calendar) -> Date {
        let comps = DateComponents(year: year, month: month, day: day, hour: 12)
        return calendar.date(from: comps) ?? Date(timeIntervalSince1970: TimeInterval(ordinal) * 86_400 + 43_200)
    }

    /// The instant at `time` on this day. If the wall-clock time is skipped by a DST jump,
    /// Foundation moves it forward to the next valid instant.
    public func date(at time: TimeOfDay, in calendar: Calendar) -> Date {
        let comps = DateComponents(year: year, month: month, day: day, hour: time.hour, minute: time.minute)
        return calendar.date(from: comps) ?? noonDate(in: calendar)
    }

    public static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: return 31
        case 4, 6, 9, 11: return 30
        default: return isLeapYear(year) ? 29 : 28
        }
    }

    public static func isLeapYear(_ y: Int) -> Bool { (y % 4 == 0 && y % 100 != 0) || y % 400 == 0 }

    public static func < (lhs: DayKey, rhs: DayKey) -> Bool { lhs.ordinal < rhs.ordinal }

    public var description: String {
        String(format: "%04d-%02d-%02d", year, month, day)
    }

    // MARK: Codable as "YYYY-MM-DD"

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let parsed = DayKey(string: raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid day \(raw)")
        }
        self = parsed
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }

    public init?(string: String) {
        let parts = string.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]), parts[2] >= 1,
              parts[2] <= DayKey.daysInMonth(year: parts[0], month: parts[1]) else { return nil }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }
}

/// A wall-clock time of day, independent of time zone.
public struct TimeOfDay: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    public let hour: Int
    public let minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = min(max(hour, 0), 23)
        self.minute = min(max(minute, 0), 59)
    }

    public init(_ date: Date, calendar: Calendar) {
        let c = calendar.dateComponents([.hour, .minute], from: date)
        self.init(hour: c.hour ?? 0, minute: c.minute ?? 0)
    }

    public var minutesSinceMidnight: Int { hour * 60 + minute }

    public static func < (lhs: TimeOfDay, rhs: TimeOfDay) -> Bool { lhs.minutesSinceMidnight < rhs.minutesSinceMidnight }

    public var description: String { String(format: "%02d:%02d", hour, minute) }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        let parts = raw.split(separator: ":").compactMap { Int($0) }
        guard parts.count == 2 else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid time \(raw)")
        }
        self.init(hour: parts[0], minute: parts[1])
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}
