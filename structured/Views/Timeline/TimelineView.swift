import SwiftUI
import SwiftData

/// Main scrollable daily timeline view
struct DayTimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: TimelineViewModel

    // Query all tasks — we filter in code for the selected date
    @Query(sort: \StructuredTask.order) private var allTasks: [StructuredTask]

    @State private var scrollPosition = ScrollPosition()

    private let leadingPadding: CGFloat = 64 // Space for hour labels

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

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // All-day tasks strip
            AllDayTasksView(
                tasks: allDayTasks,
                onToggleComplete: { viewModel.toggleCompletion($0) },
                onTap: { viewModel.startEditingTask($0) }
            )

            // Scrollable timeline
            ScrollView(.vertical, showsIndicators: false) {
                ZStack(alignment: .topLeading) {
                    // Background hour grid
                    HourGridView()

                    // Task blocks
                    ForEach(scheduledTasks, id: \.id) { task in
                        if let startTime = task.startTime {
                            let y = TimelineViewModel.yPosition(for: startTime)
                            let height = TimelineViewModel.height(for: task.duration)

                            TaskBlockView(
                                task: task,
                                onToggleComplete: { viewModel.toggleCompletion(task) },
                                onTap: { viewModel.startEditingTask(task) }
                            )
                            .frame(height: max(height, 44))
                            .padding(.leading, leadingPadding)
                            .padding(.trailing, 16)
                            .offset(y: y)
                        }
                    }

                    // Current time indicator (only on today)
                    if viewModel.isToday {
                        CurrentTimeIndicatorView(timelineWidth: 0)
                            .padding(.leading, leadingPadding - 10)
                            .padding(.trailing, 16)
                    }
                }
                .frame(height: TimelineViewModel.totalHeight + 50)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    handleTimelineTap(at: location)
                }
            }
            .scrollPosition($scrollPosition)
            .onAppear {
                let target = viewModel.initialScrollTarget()
                scrollPosition.scrollTo(y: target)
            }
            .onChange(of: viewModel.selectedDate) {
                let target = viewModel.initialScrollTarget()
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollPosition.scrollTo(y: target)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingTaskEditor) {
            TaskEditorView(
                task: viewModel.editingTask,
                selectedDate: viewModel.selectedDate
            )
        }
    }

    // MARK: - Tap to Create

    private func handleTimelineTap(at location: CGPoint) {
        // Only create if tapping on an empty area
        let tappedY = location.y
        let snappedY = TimelineViewModel.snapToQuarterHour(tappedY)
        let startTime = TimelineViewModel.dateFromYPosition(snappedY, on: viewModel.selectedDate)

        // Check if any existing task is at this position
        let tappedOnTask = scheduledTasks.contains { task in
            guard let taskStart = task.startTime else { return false }
            let taskY = TimelineViewModel.yPosition(for: taskStart)
            let taskHeight = TimelineViewModel.height(for: task.duration)
            return tappedY >= taskY && tappedY <= taskY + taskHeight
        }

        if !tappedOnTask {
            viewModel.editingTask = nil
            viewModel.showingTaskEditor = true
        }
    }
}
