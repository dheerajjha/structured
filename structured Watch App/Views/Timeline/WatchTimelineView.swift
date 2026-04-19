import SwiftUI
import SwiftData
import WatchKit

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

    /// The task currently happening right now, if any.
    private var currentTask: WatchTask? {
        guard viewModel.isToday else { return nil }
        let now = Date()
        return scheduledTasks.first { task in
            guard let start = task.startTime else { return false }
            let end = start.addingTimeInterval(task.duration)
            return start <= now && now < end && !task.isCompleted
        }
    }

    /// The next upcoming task today that hasn't started yet.
    private var nextTask: WatchTask? {
        guard viewModel.isToday else { return nil }
        let now = Date()
        return scheduledTasks.first { task in
            guard let start = task.startTime else { return false }
            return start > now && !task.isCompleted
        }
    }

    private var completionStats: (done: Int, total: Int) {
        let actionable = tasksForDate.filter { !$0.isProtected }
        let done = actionable.filter(\.isCompleted).count
        return (done, actionable.count)
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
        .onAppear {
            WatchAnchorManager.ensureAnchors(for: viewModel.selectedDate, context: modelContext)
        }
        .onChange(of: viewModel.selectedDate) { _, newDate in
            WatchAnchorManager.ensureAnchors(for: newDate, context: modelContext)
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(spacing: 2) {
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

            // Progress pill — live count of tasks completed today
            if viewModel.isToday, completionStats.total > 0 {
                progressPill
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
    }

    /// Coral-tinted progress pill showing "x of y done".
    private var progressPill: some View {
        let stats = completionStats
        let ratio = stats.total > 0 ? Double(stats.done) / Double(stats.total) : 0
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "#E8907E").opacity(0.15))
                Capsule()
                    .fill(Color(hex: "#E8907E"))
                    .frame(width: geo.size.width * ratio)
                    .animation(.easeInOut(duration: 0.25), value: ratio)
                HStack {
                    Text("\(stats.done) of \(stats.total) done")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(ratio >= 0.5 ? 1 : 0.85))
                        .padding(.leading, 6)
                    Spacer()
                }
            }
        }
        .frame(height: 12)
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
                // "Now / Next" banner — only today, only when something is live or pending
                if shouldShowBanner {
                    nowNextBanner
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 2, leading: 4, bottom: 6, trailing: 4))
                }

                // All-day tasks
                if !allDayTasks.isEmpty {
                    Section("All Day") {
                        ForEach(allDayTasks, id: \.id) { task in
                            WatchTaskRow(
                                task: task,
                                onToggleComplete: { completeWithHaptic(task) },
                                onTap: { editingTask = task }
                            )
                        }
                    }
                }

                // Scheduled tasks
                ForEach(tasks, id: \.id) { task in
                    WatchTaskRow(
                        task: task,
                        onToggleComplete: { completeWithHaptic(task) },
                        onTap: { editingTask = task }
                    )
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            completeWithHaptic(task)
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
                            WKInterfaceDevice.current().play(.directionUp)
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

    // MARK: - Now / Next Banner

    private var shouldShowBanner: Bool {
        guard viewModel.isToday else { return false }
        if currentTask != nil || nextTask != nil { return true }
        return completionStats.total > 0 && completionStats.done == completionStats.total
    }

    @ViewBuilder
    private var nowNextBanner: some View {
        if let current = currentTask {
            WatchNowNextBanner(
                title: "NOW",
                task: current,
                accent: Color(hex: current.colorHex),
                trailing: remainingMinutesLabel(for: current)
            )
            .onTapGesture { editingTask = current }
        } else if let next = nextTask {
            WatchNowNextBanner(
                title: "NEXT",
                task: next,
                accent: Color(hex: next.colorHex),
                trailing: startsInLabel(for: next)
            )
            .onTapGesture { editingTask = next }
        } else if completionStats.total > 0, completionStats.done == completionStats.total {
            WatchAllClearBanner()
        } else {
            EmptyView()
        }
    }

    private func remainingMinutesLabel(for task: WatchTask) -> String {
        guard let start = task.startTime else { return "" }
        let end = start.addingTimeInterval(task.duration)
        let remaining = max(0, Int(end.timeIntervalSince(Date()) / 60))
        if remaining <= 0 { return "now" }
        if remaining < 60 { return "\(remaining)m left" }
        let h = remaining / 60
        let m = remaining % 60
        return m > 0 ? "\(h)h \(m)m" : "\(h)h left"
    }

    private func startsInLabel(for task: WatchTask) -> String {
        guard let start = task.startTime else { return "" }
        let delta = Int(start.timeIntervalSince(Date()) / 60)
        if delta <= 0 { return "starting" }
        if delta < 60 { return "in \(delta)m" }
        let h = delta / 60
        let m = delta % 60
        return m > 0 ? "in \(h)h \(m)m" : "in \(h)h"
    }

    // MARK: - Haptics

    private func completeWithHaptic(_ task: WatchTask) {
        let willComplete = !task.isCompleted
        viewModel.toggleCompletion(task)
        WKInterfaceDevice.current().play(willComplete ? .success : .click)
    }
}

// MARK: - Now/Next Banner View

private struct WatchNowNextBanner: View {
    let title: String
    let task: WatchTask
    let accent: Color
    let trailing: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: task.iconName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(accent))

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(accent)
                    if !trailing.isEmpty {
                        Text("· \(trailing)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(task.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(accent.opacity(0.35), lineWidth: 1)
                )
        )
    }
}

// MARK: - All-Clear Banner

private struct WatchAllClearBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.green)
            Text("All clear. Nice work.")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.green.opacity(0.15))
        )
    }
}
