import SwiftUI
import SwiftData

@Observable
class TimelineViewModel {
    var selectedDate: Date = Date().startOfDay
    var showingTaskEditor = false
    var editingTask: StructuredTask?

    // MARK: - Timeline Layout Constants

    static let hourHeight: CGFloat = 70
    static let totalHeight: CGFloat = hourHeight * 24
    static let startHour: Int = 0
    static let endHour: Int = 24

    // MARK: - Date Navigation

    func goToNextDay() {
        selectedDate = selectedDate.nextDay
    }

    func goToPreviousDay() {
        selectedDate = selectedDate.previousDay
    }

    func goToToday() {
        selectedDate = Date().startOfDay
    }

    func selectDate(_ date: Date) {
        selectedDate = date.startOfDay
    }

    var isToday: Bool {
        selectedDate.isSameDay(as: Date())
    }

    // MARK: - Task Editor

    func startNewTask() {
        editingTask = nil
        showingTaskEditor = true
    }

    func startEditingTask(_ task: StructuredTask) {
        editingTask = task
        showingTaskEditor = true
    }

    // MARK: - Task Operations

    func toggleCompletion(_ task: StructuredTask) {
        withAnimation(.snappy(duration: 0.3)) {
            task.isCompleted.toggle()
        }
    }

    // MARK: - Layout Helpers

    /// Y position for a given time on the timeline
    static func yPosition(for date: Date) -> CGFloat {
        CGFloat(date.fractionalHoursSinceMidnight) * hourHeight
    }

    /// Y position for a given hour
    static func yPosition(forHour hour: Int) -> CGFloat {
        CGFloat(hour) * hourHeight
    }

    /// Height for a given duration in seconds
    static func height(for duration: TimeInterval) -> CGFloat {
        let hours = duration / 3600
        return CGFloat(hours) * hourHeight
    }

    /// Snap a Y position to the nearest 15-minute interval
    static func snapToQuarterHour(_ y: CGFloat) -> CGFloat {
        let quarterHourHeight = hourHeight / 4
        return (y / quarterHourHeight).rounded() * quarterHourHeight
    }

    /// Convert Y position to a Date on the given day
    static func dateFromYPosition(_ y: CGFloat, on day: Date) -> Date {
        let totalMinutes = (y / totalHeight) * 1440
        let hour = Int(totalMinutes) / 60
        let minute = Int(totalMinutes) % 60
        return day.atTime(hour: min(23, max(0, hour)), minute: min(59, max(0, minute)))
    }

    /// Scroll target for current time or start of day
    func initialScrollTarget() -> CGFloat {
        if isToday {
            return max(0, TimelineViewModel.yPosition(for: Date()) - 200)
        } else {
            // Scroll to 7 AM
            return TimelineViewModel.yPosition(forHour: 7)
        }
    }
}
