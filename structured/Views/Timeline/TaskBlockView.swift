import SwiftUI

/// Individual task block on the timeline — positioned by time
struct TaskBlockView: View {
    let task: StructuredTask
    let onToggleComplete: () -> Void
    let onTap: () -> Void

    private var taskColor: Color { Color(hex: task.colorHex) }
    private var blockHeight: CGFloat {
        max(TimelineViewModel.height(for: task.duration), 56)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Colored icon circle
                TaskIconView(
                    iconName: task.iconName,
                    colorHex: task.colorHex,
                    size: blockHeight > 50 ? 40 : 32
                )

                // Title + time info
                VStack(alignment: .leading, spacing: 2) {
                    if blockHeight > 50 {
                        Text(task.timeRangeString)
                            .font(.caption)
                            .foregroundStyle(taskColor.opacity(0.8))
                    }

                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(blockHeight > 70 ? 2 : 1)

                    // Show subtask progress if space allows
                    if blockHeight > 85, let subtasks = task.subtasks, !subtasks.isEmpty {
                        let completed = subtasks.filter(\.isCompleted).count
                        Text("\(completed)/\(subtasks.count) subtasks")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Completion circle
                Button {
                    onToggleComplete()
                } label: {
                    CompletionCircleView(
                        isCompleted: task.isCompleted,
                        colorHex: task.colorHex
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: blockHeight)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(taskColor.pastel(opacity: task.isCompleted ? 0.08 : 0.15))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(taskColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 12) {
        TaskBlockView(
            task: {
                let t = StructuredTask(
                    title: "Morning Yoga",
                    startTime: Date().atTime(hour: 8, minute: 15),
                    duration: 1800,
                    colorHex: "#34C759",
                    iconName: "figure.yoga"
                )
                return t
            }(),
            onToggleComplete: {},
            onTap: {}
        )

        TaskBlockView(
            task: {
                let t = StructuredTask(
                    title: "Study for Exam",
                    startTime: Date().atTime(hour: 9),
                    duration: 7200,
                    colorHex: "#FF6B6B",
                    iconName: "book.fill"
                )
                return t
            }(),
            onToggleComplete: {},
            onTap: {}
        )
    }
    .padding()
}
