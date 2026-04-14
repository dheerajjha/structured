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
    var iconName: String = "checklist"
    var isCompleted: Bool = false
    var isAllDay: Bool = false
    var isInbox: Bool = false
    var order: Int = 0
    var createdAt: Date = Date()

    // Anchor task fields
    /// "wake_up" | "wind_down" | nil
    var anchorType: String? = nil
    /// True for Rise and Shine / Wind Down — protected from AI and bulk moves
    var isProtected: Bool = false
    /// True once user manually edits this specific day's anchor time
    var isUserModifiedTime: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Subtask.task)
    var subtasks: [Subtask]? = []

    init(
        title: String,
        startTime: Date? = nil,
        duration: TimeInterval = 1800,
        date: Date = Date(),
        notes: String = "",
        colorHex: String = "#FF6B6B",
        iconName: String = "checklist",
        isCompleted: Bool = false,
        isAllDay: Bool = false,
        isInbox: Bool = false,
        order: Int = 0,
        anchorType: String? = nil,
        isProtected: Bool = false
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
        self.anchorType = anchorType
        self.isProtected = isProtected
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
