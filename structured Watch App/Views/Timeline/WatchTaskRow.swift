import SwiftUI

struct WatchTaskRow: View {
    let task: WatchTask
    let onToggleComplete: () -> Void
    let onTap: () -> Void

    private var taskColor: Color { Color(hex: task.colorHex) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                WatchTaskIconView(
                    iconName: task.iconName,
                    colorHex: task.colorHex,
                    size: 22
                )

                VStack(alignment: .leading, spacing: 1) {
                    // Time + duration on one line
                    HStack(spacing: 4) {
                        Text(task.compactTimeString)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(taskColor.opacity(0.8))
                        if !task.durationLabel.isEmpty {
                            Text("·")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                            Text(task.durationLabel)
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text(task.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    onToggleComplete()
                } label: {
                    WatchCompletionCircle(
                        isCompleted: task.isCompleted,
                        colorHex: task.colorHex,
                        size: 18
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(taskColor.pastel(opacity: task.isCompleted ? 0.08 : 0.15))
        )
    }
}
