import SwiftUI
import SwiftData

// MARK: - Timeline Item Model

private enum TimelineItem: Identifiable {
    case task(StructuredTask)
    case gap(minutes: Int, afterTaskID: UUID)
    case currentTime(date: Date)

    var id: String {
        switch self {
        case .task(let t):        return "task-\(t.id)"
        case .gap(_, let tid):    return "gap-after-\(tid)"
        case .currentTime(let d): return "now-\(Int(d.timeIntervalSince1970 / 60))"
        }
    }
}

// MARK: - Day Timeline View

struct DayTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: TimelineViewModel

    @Query(sort: \StructuredTask.order) private var allTasks: [StructuredTask]

    // MARK: - Filtered Tasks

    private var tasksForDate: [StructuredTask] {
        allTasks.filter { $0.date.isSameDay(as: viewModel.selectedDate) && !$0.isInbox }
    }

    private var scheduledTasks: [StructuredTask] {
        tasksForDate
            .filter { !$0.isAllDay && $0.startTime != nil }
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }

    private var allDayTasks: [StructuredTask] {
        tasksForDate.filter(\.isAllDay)
    }

    // MARK: - Build Items

    private func buildItems(from tasks: [StructuredTask], isToday: Bool) -> [TimelineItem] {
        guard !tasks.isEmpty else { return [] }
        var items: [TimelineItem] = []
        let now = Date()

        for (index, task) in tasks.enumerated() {
            if isToday && index == 0 {
                if let first = tasks.first?.startTime, now < first {
                    items.append(.currentTime(date: now))
                }
            }

            if index > 0 {
                let prev = tasks[index - 1]
                let prevEnd = (prev.startTime ?? .distantPast).addingTimeInterval(prev.duration)
                if let thisStart = task.startTime {
                    let gapSecs = thisStart.timeIntervalSince(prevEnd)
                    if gapSecs >= 15 * 60 {
                        if isToday && now >= prevEnd && now < thisStart {
                            items.append(.currentTime(date: now))
                        }
                        items.append(.gap(minutes: Int(gapSecs / 60), afterTaskID: prev.id))
                    }
                }
            }

            items.append(.task(task))
        }

        if isToday {
            let lastEnd = (tasks.last?.startTime ?? .distantPast)
                .addingTimeInterval(tasks.last?.duration ?? 0)
            if now >= lastEnd {
                items.append(.currentTime(date: now))
            }
        }

        return items
    }

    // MARK: - Task Actions

    private func unscheduleTask(_ task: StructuredTask) {
        withAnimation {
            task.isInbox = true
            task.startTime = nil
        }
    }

    private func deleteTask(_ task: StructuredTask) {
        withAnimation {
            modelContext.delete(task)
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            AllDayTasksView(
                tasks: allDayTasks,
                onToggleComplete: { viewModel.toggleCompletion($0) },
                onTap: { viewModel.startEditingTask($0) }
            )
            taskContent
        }
        .sheet(isPresented: $viewModel.showingTaskEditor) {
            TaskEditorView(
                task: viewModel.editingTask,
                selectedDate: viewModel.selectedDate,
                presetStartTime: viewModel.newTaskStartTime
            )
        }
        .onChange(of: viewModel.showingTaskEditor) { _, showing in
            if !showing { viewModel.newTaskStartTime = nil }
        }
    }

    @ViewBuilder
    private var taskContent: some View {
        let tasks = scheduledTasks
        if tasks.isEmpty {
            emptyState
        } else {
            let items = buildItems(from: tasks, isToday: viewModel.isToday)
            List {
                Color.clear.frame(height: 8)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())

                ForEach(items) { item in
                    rowView(for: item)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
                }

                Color.clear.frame(height: 100)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .scrollIndicators(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
        }
    }

    // MARK: - Row View  (Options A + B wired here)

    @ViewBuilder
    private func rowView(for item: TimelineItem) -> some View {
        switch item {
        case .task(let task):
            TaskBlockView(
                task: task,
                onToggleComplete: { viewModel.toggleCompletion(task) },
                onTap: { viewModel.startEditingTask(task) }
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            // Option B — long press context menu
            .contextMenu {
                Button { viewModel.startEditingTask(task) } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button { unscheduleTask(task) } label: {
                    Label("Move to Unscheduled", systemImage: "tray.fill")
                }
                Divider()
                Button(role: .destructive) { deleteTask(task) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            // Option A — swipe left to reveal Unschedule + Delete
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) { deleteTask(task) } label: {
                    Label("Delete", systemImage: "trash")
                }
                Button { unscheduleTask(task) } label: {
                    Label("Unschedule", systemImage: "tray.fill")
                }
                .tint(.orange)
            }

        case .gap(let minutes, let afterTaskID):
            gapView(minutes: minutes, afterTaskID: afterTaskID)

        case .currentTime(let date):
            currentTimeBadge(for: date)
        }
    }

    // MARK: - Current Time Badge

    private func currentTimeBadge(for date: Date) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(.red)
                .frame(width: 8, height: 8)
            Text(TimeFormatting.timeString(from: date))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.red)
            Rectangle()
                .fill(.red.opacity(0.25))
                .frame(height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - Gap View

    private func gapView(minutes: Int, afterTaskID: UUID) -> some View {
        HStack(spacing: 8) {
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(.systemGray4))
                        .frame(width: 2, height: 4)
                }
            }
            .frame(width: 16)
            .padding(.leading, 20)

            Text(gapLabel(minutes: minutes))
                .font(.caption)
                .foregroundStyle(Color(.systemGray3))

            if minutes >= 60 {
                Button {
                    // Find the task that precedes this gap to compute start time
                    if let prevTask = allTasks.first(where: { $0.id == afterTaskID }),
                       let prevEnd = prevTask.startTime?.addingTimeInterval(prevTask.duration) {
                        viewModel.addTaskAt(time: prevEnd)
                    } else {
                        viewModel.showingTaskEditor = true
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.caption)
                        Text("Add Task")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(Color(hex: "#E8907E"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color(hex: "#E8907E").opacity(0.1)))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .frame(minHeight: 28)
    }

    private func gapLabel(minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h) hr \(m) min free" : "\(h) hr free"
        }
        return "\(minutes) min free"
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Color(.systemGray4))
            Text("No tasks scheduled")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Tap + to add your first task.")
                .font(.subheadline)
                .foregroundStyle(Color(.systemGray3))
            Spacer()
        }
        .padding(.horizontal, 40)
    }
}
