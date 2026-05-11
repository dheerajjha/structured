import Foundation
import SwiftData

@Model
class WatchTask {
    var id: UUID = UUID()
    var title: String = ""
    var startTime: Date?
    var duration: TimeInterval = 1800
    var date: Date = Date()
    var notes: String = ""
    var colorHex: String = "#FF6B6B"
    var iconName: String = "checklist"
    var isCompleted: Bool = false
    var isAllDay: Bool = false
    var isInbox: Bool = false
    var order: Int = 0
    var createdAt: Date = Date()
    var modifiedAt: Date = Date()

    // Anchor task fields
    var anchorType: String? = nil
    var isProtected: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \WatchSubtask.task)
    var subtasks: [WatchSubtask]? = []

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
        self.modifiedAt = Date()
    }
}

// MARK: - Computed Properties

extension WatchTask {
    var endTime: Date? {
        guard let start = startTime else { return nil }
        return start.addingTimeInterval(duration)
    }

    var sortedSubtasks: [WatchSubtask] {
        (subtasks ?? []).sorted { $0.order < $1.order }
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    var timeRangeString: String {
        guard let start = startTime else {
            return String(localized: "All Day", comment: "Watch time-range label shown on a task row when no specific start time is set")
        }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        let startStr = formatter.string(from: start)
        if duration == 0 { return startStr }
        let endStr = formatter.string(from: start.addingTimeInterval(duration))
        return String(localized: "\(startStr) – \(endStr)", comment: "Watch task time range — start and end time joined by an en dash. %1$@ start, %2$@ end.")
    }

    var compactTimeString: String {
        guard let start = startTime else {
            return String(localized: "All Day", comment: "Watch compact time label when no specific start time is set")
        }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("jmm")
        return formatter.string(from: start)
    }

    var durationLabel: String {
        let mins = durationMinutes
        if mins == 0 { return "" }
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            if m > 0 {
                return String(localized: "\(h)h \(m)m", comment: "Compact watch duration label — hours and minutes (e.g. '1h 30m')")
            }
            return String(localized: "\(h)h", comment: "Compact watch duration label — whole hours (e.g. '2h')")
        }
        return String(localized: "\(mins)m", comment: "Compact watch duration label — minutes under an hour (e.g. '15m')")
    }
}
