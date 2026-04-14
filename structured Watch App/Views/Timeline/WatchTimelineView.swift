import SwiftUI
import SwiftData

struct WatchTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: WatchTimelineViewModel
    @Query(sort: \WatchTask.order) private var allTasks: [WatchTask]

    @State private var showingTaskEditor = false
    @State private var editingTask: WatchTask?

    private var tasksForDate: [WatchTask] {
        allTasks.filter { $0.date.isSameDay(as: viewModel.selectedDate) && !$0.isInbox }
    }

    private var scheduledTasks: [WatchTask] {
        tasksForDate
            .filter { !$0.isAllDay && $0.startTime != nil }
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }

    private var allDayTasks: [WatchTask] {
        tasksForDate.filter(\.isAllDay)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                dateHeader
                taskList
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingTaskEditor = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingTaskEditor) {
                WatchTaskEditorView(task: nil, selectedDate: viewModel.selectedDate)
            }
            .sheet(item: $editingTask) { task in
                WatchTaskEditorView(task: task, selectedDate: viewModel.selectedDate)
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            Button { viewModel.goToPreviousDay() } label: {
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.semibold))
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(spacing: 1) {
                if viewModel.isToday {
                    Text("Today")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color(hex: "#E8907E"))
                }
                Text(viewModel.selectedDate.compactDateString)
                    .font(.caption.weight(.semibold))
            }

            Spacer()

            Button { viewModel.goToNextDay() } label: {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Task List

    @ViewBuilder
    private var taskList: some View {
        let tasks = scheduledTasks
        if tasks.isEmpty && allDayTasks.isEmpty {
            VStack(spacing: 8) {
                Spacer()
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(.gray))
                Text("No tasks")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button { showingTaskEditor = true } label: {
                    Label("Add Task", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: "#E8907E"))
                Spacer()
            }
        } else {
            List {
                // All-day tasks
                if !allDayTasks.isEmpty {
                    Section("All Day") {
                        ForEach(allDayTasks, id: \.id) { task in
                            WatchTaskRow(
                                task: task,
                                onToggleComplete: { viewModel.toggleCompletion(task) },
                                onTap: { editingTask = task }
                            )
                        }
                    }
                }

                // Scheduled tasks
                ForEach(tasks, id: \.id) { task in
                    WatchTaskRow(
                        task: task,
                        onToggleComplete: { viewModel.toggleCompletion(task) },
                        onTap: { editingTask = task }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            viewModel.toggleCompletion(task)
                        } label: {
                            Label("Done", systemImage: "checkmark")
                        }
                        .tint(.green)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            withAnimation {
                                task.isInbox = true
                                task.startTime = nil
                                task.modifiedAt = Date()
                            }
                        } label: {
                            Label("Later", systemImage: "tray")
                        }
                        .tint(.orange)
                    }
                }

                // Current time indicator
                if viewModel.isToday {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(.red)
                            .frame(width: 6, height: 6)
                        Text(WatchTimeFormatting.timeString(from: Date()))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.carousel)
        }
    }
}
