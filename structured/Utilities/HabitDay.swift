import Foundation

/// Single source of truth for streak / day-bucket / anchor math. All
/// consumers that compute daily-anchor day buckets, "today"
/// comparisons, or day-difference checks go through here so a future
/// "lock to home TZ" preference is a one-line change.
///
/// Today the calendar still uses `TimeZone.current` (so behaviour
/// matches the previous direct `Calendar.current` usage). The point of
/// this helper is the *routing*, not a behavioural change.
enum HabitDay {
    /// Calendar configured for streak/day-bucket math. Today's TimeZone
    /// is used as the "habit-day origin"; a future preference can swap
    /// this for a fixed/home TZ without touching consumer call sites.
    static var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone.current
        c.locale = Locale(identifier: "en_US_POSIX")
        return c
    }

    /// Stable `yyyy-MM-dd` key for grouping/comparing days. Use this
    /// instead of comparing `Date` instances directly.
    static func key(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = calendar.locale
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Start of the habit-day containing `date` (midnight in the
    /// helper's TimeZone).
    static func startOfDay(for date: Date) -> Date {
        calendar.startOfDay(for: date)
    }

    /// One habit-day after `startOfDay`. Use this paired with
    /// `startOfDay` to form a half-open `[start, next)` range when
    /// matching anchor tasks for a given day, instead of comparing
    /// `Date` instances for exact equality.
    static func nextStartOfDay(for date: Date) -> Date {
        let cal = calendar
        let start = cal.startOfDay(for: date)
        return cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86400)
    }

    /// Difference in habit-days between two instants. Handles DST and
    /// short-day boundaries via Calendar's component arithmetic.
    static func dayDifference(from: Date, to: Date) -> Int {
        let cal = calendar
        let a = cal.startOfDay(for: from)
        let b = cal.startOfDay(for: to)
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }

    /// Are these two instants on the same habit-day?
    static func isSameDay(_ a: Date, _ b: Date) -> Bool {
        key(for: a) == key(for: b)
    }
}
