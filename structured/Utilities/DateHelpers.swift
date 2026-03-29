import Foundation

extension Date {
    /// Start of the calendar day (midnight)
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    /// Hour component (0-23)
    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    /// Minute component (0-59)
    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    /// Minutes since midnight
    var minutesSinceMidnight: Double {
        Double(hour * 60 + minute)
    }

    /// Fractional hours since midnight (e.g. 9:30 = 9.5)
    var fractionalHoursSinceMidnight: Double {
        minutesSinceMidnight / 60.0
    }

    /// Is this date today?
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    /// Is the same calendar day as another date?
    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    /// Move to next day
    var nextDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }

    /// Move to previous day
    var previousDay: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }

    /// Create a date with specific hour and minute on this day
    func atTime(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: self)!
    }

    /// Short day name (Mon, Tue, ...)
    var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    /// Day number (1-31)
    var dayNumber: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Formatted as "13. May 2026"
    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d. MMMM yyyy"
        return formatter.string(from: self)
    }

    /// Formatted as "May 2026"
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    /// Days of the current week (Mon-Sun)
    var weekDays: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: self)
        // Adjust so Monday = 1
        let mondayOffset = (weekday + 5) % 7
        let monday = calendar.date(byAdding: .day, value: -mondayOffset, to: startOfDay)!
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: monday)! }
    }
}

// MARK: - Time Formatting

enum TimeFormatting {
    static func hourLabel(for hour: Int) -> String {
        if hour == 0 { return "12 AM" }
        if hour < 12 { return "\(hour) AM" }
        if hour == 12 { return "12 PM" }
        return "\(hour - 12) PM"
    }

    static func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
