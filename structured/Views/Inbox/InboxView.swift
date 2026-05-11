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
                            .listRowInsets(.init(top: scaled(5), leading: scaled(16), bottom: scaled(5), trailing: scaled(16)))
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
        VStack(spacing: scaled(20)) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: scaled(48)))
                .foregroundStyle(Color(.systemGray4))
            Text("No tasks yet", comment: "Empty-state title on Inbox (Later) tab when user has no unscheduled tasks")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Tasks without a scheduled time live here.\nGreat for capturing ideas and to-dos.", comment: "Empty-state body on Inbox tab. \\n is a literal line break — keep it.")
                .font(.subheadline)
                .foregroundStyle(Color(.systemGray3))
                .multilineTextAlignment(.center)

            Button {
                showingNewTask = true
            } label: {
                HStack(spacing: scaled(8)) {
                    Image(systemName: "plus.circle.fill")
                        .font(.body)
                    Text("Add Task", comment: "Primary CTA button label on Inbox empty state")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, scaled(24))
                .padding(.vertical, scaled(12))
                .background(Capsule().fill(Color(hex: "#E8907E")))
            }
            .padding(.top, scaled(4))

            Spacer()
        }
        .padding(.horizontal, scaled(40))
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
            if m > 0 {
                return String(localized: "\(h) hr, \(m) min", comment: "Inbox row duration — hours and minutes (e.g. '1 hr, 30 min')")
            }
            return String(localized: "\(h) hr", comment: "Inbox row duration — whole hours (e.g. '2 hr')")
        }
        return String(localized: "\(mins) min", comment: "Inbox row duration — minutes under an hour (e.g. '15 min')")
    }

    var body: some View {
        HStack(spacing: scaled(14)) {
            TaskIconView(iconName: task.iconName, colorHex: task.colorHex, size: scaled(44))

            VStack(alignment: .leading, spacing: scaled(2)) {
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
                    .frame(width: scaled(36), height: scaled(36))
                    .background(Color(hex: task.colorHex).opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, scaled(16))
        .padding(.vertical, scaled(12))
        .background(
            RoundedRectangle(cornerRadius: scaled(16))
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.04), radius: scaled(6), y: scaled(2))
        )
    }
}
