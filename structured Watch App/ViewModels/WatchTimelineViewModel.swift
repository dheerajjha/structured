import SwiftUI
import SwiftData

@Observable
class WatchTimelineViewModel {
    var selectedDate: Date = Date().startOfDay

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

    var isToday: Bool {
        selectedDate.isSameDay(as: Date())
    }

    // MARK: - Task Operations

    func toggleCompletion(_ task: WatchTask) {
        withAnimation(.snappy(duration: 0.3)) {
            task.isCompleted.toggle()
            task.modifiedAt = Date()
        }
    }
}
