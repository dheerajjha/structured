import SwiftUI
import SwiftData

// MARK: - Inbox View

struct InboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<StructuredTask> { $0.isInbox },
        sort: \StructuredTask.createdAt,
        order: .reverse
    )
    private var inboxTasks: [StructuredTask]

    @State private var editingTask: StructuredTask?
    @State private var showingNewTask = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                if inboxTasks.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(inboxTasks) { task in
                            InboxRowView(task: task) {
                                editingTask = task
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init(top: 5, leading: 16, bottom: 5, trailing: 16))
                            .contextMenu {
                                Button {
                                    editingTask = task
                                    Analytics.track(Analytics.Event.inboxTaskScheduleTapped, properties: ["source": "context_menu"])
                                } label: {
                                    Label("Schedule", systemImage: "calendar.badge.plus")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    Analytics.track(Analytics.Event.taskDeleted, properties: ["source": "inbox_context_menu"])
                                    withAnimation { modelContext.delete(task) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    Analytics.track(Analytics.Event.taskDeleted, properties: ["source": "inbox_swipe"])
                                    withAnimation { modelContext.delete(task) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    editingTask = task
                                    Analytics.track(Analytics.Event.inboxTaskScheduleTapped, properties: ["source": "swipe"])
                                } label: {
                                    Label("Schedule", systemImage: "calendar.badge.plus")
                                }
                                .tint(Color(hex: "#E8907E"))
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Unscheduled")
        }
        .onAppear {
            Analytics.track(Analytics.Event.inboxViewed, properties: ["task_count": inboxTasks.count])
        }
        .sheet(item: $editingTask) { task in
            // Opening from row schedules the task → clears isInbox on save
            TaskEditorView(task: task, selectedDate: Date())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundStyle(Color(.systemGray4))
            Text("No tasks yet")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Tasks without a scheduled time live here.\nGreat for capturing ideas and to-dos.")
                .font(.subheadline)
                .foregroundStyle(Color(.systemGray3))
                .multilineTextAlignment(.center)

            Button {
                showingNewTask = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                    Text("Add Task")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color(hex: "#E8907E")))
            }
            .padding(.top, 4)

            Spacer()
        }
        .padding(.horizontal, 40)
        .sheet(isPresented: $showingNewTask) {
            TaskEditorView(task: nil, selectedDate: Date(), startAsInbox: true)
        }
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
