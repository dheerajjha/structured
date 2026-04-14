import SwiftUI

/// Horizontal strip showing all-day tasks above the timeline
struct AllDayTasksView: View {
    let tasks: [StructuredTask]
    let onToggleComplete: (StructuredTask) -> Void
    let onTap: (StructuredTask) -> Void

    var body: some View {
        if !tasks.isEmpty {
            VStack(alignment: .leading, spacing: scaled(8)) {
                Text("ALL DAY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, scaled(16))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: scaled(8)) {
                        ForEach(tasks, id: \.id) { task in
                            allDayChip(task)
                        }
                    }
                    .padding(.horizontal, scaled(16))
                }
            }
            .padding(.vertical, scaled(8))
            .background(.ultraThinMaterial)
        }
    }

    @ViewBuilder
    private func allDayChip(_ task: StructuredTask) -> some View {
        Button {
            onTap(task)
        } label: {
            HStack(spacing: scaled(8)) {
                TaskIconView(
                    iconName: task.iconName,
                    colorHex: task.colorHex,
                    size: scaled(28)
                )

                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)

                Button {
                    onToggleComplete(task)
                } label: {
                    CompletionCircleView(
                        isCompleted: task.isCompleted,
                        colorHex: task.colorHex,
                        size: scaled(22)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, scaled(12))
            .padding(.vertical, scaled(8))
            .background(
                RoundedRectangle(cornerRadius: scaled(10))
                    .fill(Color(hex: task.colorHex).pastel())
            )
        }
        .buttonStyle(.plain)
    }
}
