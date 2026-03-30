import SwiftUI
import SwiftData

// MARK: - Inbox View

struct InboxView: View {
    @Query(
        filter: #Predicate<StructuredTask> { $0.isInbox },
        sort: \StructuredTask.createdAt,
        order: .reverse
    )
    private var inboxTasks: [StructuredTask]

    @State private var editingTask: StructuredTask?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if inboxTasks.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(inboxTasks) { task in
                                InboxRowView(task: task) {
                                    editingTask = task
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationTitle("Unscheduled")
        }
        .sheet(item: $editingTask) { task in
            // Opening from row schedules the task → clears isInbox on save
            TaskEditorView(task: task, selectedDate: Date())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(Color(.systemGray4))
            Text("Nothing unscheduled")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Tap + to capture tasks without a time.")
                .font(.subheadline)
                .foregroundStyle(Color(.systemGray3))
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}

// MARK: - Inbox Row

struct InboxRowView: View {
    let task: StructuredTask
    let onSchedule: () -> Void

    private var durationLabel: String {
        let mins = task.durationMinutes
        if mins == 0 { return "" }
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            return m > 0 ? "\(h) hr, \(m) min" : "\(h) hr"
        }
        return "\(mins) min"
    }

    var body: some View {
        HStack(spacing: 14) {
            TaskIconView(iconName: task.iconName, colorHex: task.colorHex, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                if !durationLabel.isEmpty {
                    Text(durationLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }

            Spacer()

            Button(action: onSchedule) {
                Image(systemName: "plus")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color(hex: task.colorHex))
                    .frame(width: 36, height: 36)
                    .background(Color(hex: task.colorHex).opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
    }
}
