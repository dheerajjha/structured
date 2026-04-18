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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                dateHeader
                taskList
            }

            // Floating add button
            Button { showingTaskEditor = true } label: {
                Image(systemName: "plus")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Color(hex: "#E8907E")))
                    .shadow(color: .black.opacity(0.3), radius: 3, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 6)
            .padding(.bottom, 2)
        }
        .sheet(isPresented: $showingTaskEditor) {
            WatchTaskEditorView(task: nil, selectedDate: viewModel.selectedDate)
        }
        .sheet(item: $editingTask) { task in
            WatchTaskEditorView(task: task, selectedDate: viewModel.selectedDate)
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack(spacing: 12) {
            Button { viewModel.goToPreviousDay() } label: {
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.semibold))
            }
            .buttonStyle(.plain)

            Spacer()

            Text(dateHeaderLabel)
                .font(.caption.weight(.bold))
                .foregroundStyle(viewModel.isToday ? Color(hex: "#E8907E") : .primary)

            Spacer()

            Button { viewModel.goToNextDay() } label: {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }

    private var dateHeaderLabel: String {
        if viewModel.isToday {
            return "Today, \(viewModel.selectedDate.compactDateString)"
        } else if Calendar.current.isDateInTomorrow(viewModel.selectedDate) {
            return "Tomorrow"
        } else if Calendar.current.isDateInYesterday(viewModel.selectedDate) {
            return "Yesterday"
        } else {
            return viewModel.selectedDate.compactDateString
        }
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
                            WatchConnectivityManager.shared.sendTaskUpdate(
                                "unschedule", taskId: task.id.uuidString
                            )
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

                // Bottom spacer so FAB doesn't overlap last row
                Color.clear.frame(height: 36)
                    .listRowBackground(Color.clear)
            }
            .listStyle(.carousel)
        }
    }
}
