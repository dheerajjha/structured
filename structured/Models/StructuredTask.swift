import Foundation
import SwiftData

@Model
class StructuredTask {
    var id: UUID = UUID()
    var title: String = ""
    var startTime: Date?
    var duration: TimeInterval = 1800 // 30 minutes default
    var date: Date = Date()
    var notes: String = ""
    var colorHex: String = "#FF6B6B"
    var iconName: String = "star.fill"
    var isCompleted: Bool = false
    var isAllDay: Bool = false
    var isInbox: Bool = false
    var order: Int = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \Subtask.task)
    var subtasks: [Subtask]? = []

    init(
        title: String,
        startTime: Date? = nil,
        duration: TimeInterval = 1800,
        date: Date = Date(),
        notes: String = "",
        colorHex: String = "#FF6B6B",
        iconName: String = "star.fill",
        isCompleted: Bool = false,
        isAllDay: Bool = false,
        isInbox: Bool = false,
        order: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.startTime = startTime
        self.duration = duration
        self.date = date
        self.notes = notes
        self.colorHex = colorHex
        self.iconName = iconName
        self.isCompleted = isCompleted
        self.isAllDay = isAllDay
        self.isInbox = isInbox
        self.order = order
        self.createdAt = Date()
    }
}

// MARK: - Computed Properties

extension StructuredTask {
    var endTime: Date? {
        guard let start = startTime else { return nil }
        return start.addingTimeInterval(duration)
    }

    var sortedSubtasks: [Subtask] {
        (subtasks ?? []).sorted { $0.order < $1.order }
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    var timeRangeString: String {
        guard let start = startTime else { return "All Day" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let startStr = formatter.string(from: start)
        if duration == 0 { return startStr }
        let endStr = formatter.string(from: start.addingTimeInterval(duration))
        let mins = durationMinutes
        if mins >= 60 {
            let hours = mins / 60
            let remaining = mins % 60
            if remaining == 0 {
                return "\(startStr) - \(endStr) (\(hours) hr)"
            } else {
                return "\(startStr) - \(endStr) (\(hours) hr \(remaining) min)"
            }
        }
        return "\(startStr) - \(endStr) (\(mins) min)"
    }
}
