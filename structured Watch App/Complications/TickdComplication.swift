import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Timeline Entry

struct TickdEntry: TimelineEntry {
    let date: Date
    let nextTask: TaskSnapshot?
    let upcomingTasks: [TaskSnapshot]
    let remainingCount: Int
}

struct TaskSnapshot {
    let title: String
    let time: String
    let colorHex: String
    let iconName: String
}

// MARK: - Provider

struct TickdComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> TickdEntry {
        TickdEntry(
            date: Date(),
            nextTask: TaskSnapshot(title: "Morning Yoga", time: "9:00 AM", colorHex: "#34C759", iconName: "figure.yoga"),
            upcomingTasks: [
                TaskSnapshot(title: "Morning Yoga", time: "9:00 AM", colorHex: "#34C759", iconName: "figure.yoga"),
                TaskSnapshot(title: "Team Standup", time: "10:00 AM", colorHex: "#007AFF", iconName: "person.2.fill"),
            ],
            remainingCount: 5
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (TickdEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TickdEntry>) -> Void) {
        let entry = makeEntry()
        let refresh = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(refresh)))
    }

    private func makeEntry() -> TickdEntry {
        // Complications can't use @Query — read from UserDefaults or App Group
        // For now, return placeholder data; will be wired to shared store later
        TickdEntry(
            date: Date(),
            nextTask: nil,
            upcomingTasks: [],
            remainingCount: 0
        )
    }
}

// MARK: - Circular Complication

struct TickdCircularView: View {
    let entry: TickdEntry
    private let coral = Color(hex: "#E8907E")

    var body: some View {
        if let task = entry.nextTask {
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 1) {
                    Image(systemName: task.iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color(hex: task.colorHex))
                    Text(task.time)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
            }
        }
    }
}

// MARK: - Rectangular Complication

struct TickdRectangularView: View {
    let entry: TickdEntry
    private let coral = Color(hex: "#E8907E")

    var body: some View {
        if entry.upcomingTasks.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text("Tickd")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(coral)
                Text("All clear!")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(entry.upcomingTasks.prefix(2), id: \.title) { task in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: task.colorHex))
                            .frame(width: 6, height: 6)
                        Text(task.time)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                        Text(task.title)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

// MARK: - Corner Complication

struct TickdCornerView: View {
    let entry: TickdEntry

    var body: some View {
        Text("\(entry.remainingCount)")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(Color(hex: "#E8907E"))
            .widgetLabel {
                Text("tasks left")
            }
    }
}

// MARK: - Inline Complication

struct TickdInlineView: View {
    let entry: TickdEntry

    var body: some View {
        if let task = entry.nextTask {
            Text("Next: \(task.title) at \(task.time)")
        } else {
            Text("All tasks done!")
        }
    }
}

// MARK: - Widget

struct TickdComplication: Widget {
    let kind: String = "TickdComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TickdComplicationProvider()) { entry in
            TickdComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Tickd")
        .description("See your next task at a glance.")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline,
        ])
    }
}

// MARK: - Multi-family rendering

struct TickdComplicationEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: TickdEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            TickdCircularView(entry: entry)
        case .accessoryRectangular:
            TickdRectangularView(entry: entry)
        case .accessoryCorner:
            TickdCornerView(entry: entry)
        case .accessoryInline:
            TickdInlineView(entry: entry)
        default:
            TickdCircularView(entry: entry)
        }
    }
}
