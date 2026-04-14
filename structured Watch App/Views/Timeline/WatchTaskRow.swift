import SwiftUI

struct WatchTaskRow: View {
    let task: WatchTask
    let onToggleComplete: () -> Void
    let onTap: () -> Void

    private var taskColor: Color { Color(hex: task.colorHex) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                WatchTaskIconView(
                    iconName: task.iconName,
                    colorHex: task.colorHex,
                    size: 28
                )

                VStack(alignment: .leading, spacing: 1) {
                    Text(task.compactTimeString)
                        .font(.caption2)
                        .foregroundStyle(taskColor.opacity(0.8))

                    Text(task.title)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(task.isCompleted ? .secondary : .primary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(1)

                    if !task.durationLabel.isEmpty {
                        Text(task.durationLabel)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    onToggleComplete()
                } label: {
                    WatchCompletionCircle(
                        isCompleted: task.isCompleted,
                        colorHex: task.colorHex,
                        size: 20
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .listRowBackground(
            RoundedRectangle(cornerRadius: 10)
                .fill(taskColor.pastel(opacity: task.isCompleted ? 0.08 : 0.15))
        )
    }
}
