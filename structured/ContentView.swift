import SwiftUI
import SwiftData

// MARK: - App Tabs

enum AppTab: CaseIterable {
    case unscheduled, timeline, ai, settings

    var title: String {
        switch self {
        case .unscheduled: return "Later"
        case .timeline:    return "Today"
        case .ai:          return "AI"
        case .settings:    return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .unscheduled: return "tray.fill"
        case .timeline:    return "list.bullet.below.rectangle"
        case .ai:          return "sparkles"
        case .settings:    return "gearshape.fill"
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var selectedTab: AppTab = .timeline
    @State private var viewModel = TimelineViewModel()
    @State private var aiViewModel = AIViewModel()
    @Query(sort: \StructuredTask.order) private var allTasks: [StructuredTask]
    @State private var showingTaskEditor = false
    @State private var showDatePicker = false
    @State private var pianoRevealed = false
    @State private var sheetDragOffset: CGFloat = 0

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding)
                .onChange(of: hasCompletedOnboarding) { _, completed in
                    if completed { ensureAnchorsForCurrentDate() }
                }
        } else {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // Push content up so nothing hides behind the tab bar
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomBar
                }
                .sheet(isPresented: $showingTaskEditor) {
                    if selectedTab == .unscheduled {
                        TaskEditorView(task: nil, selectedDate: Date(), startAsInbox: true)
                    } else {
                        TaskEditorView(task: nil, selectedDate: viewModel.selectedDate)
                    }
                }
                .onAppear { ensureAnchorsForCurrentDate() }
                .onChange(of: viewModel.selectedDate) { _, newDate in
                    DailyAnchorManager.ensureAnchors(for: newDate, context: modelContext)
                }
                .onChange(of: aiViewModel.pendingActions.count) { _, count in
                    guard count > 0 else { return }
                    executeAIActions(aiViewModel.pendingActions)
                    aiViewModel.pendingActions = []
                }
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            InboxView()
                .opacity(selectedTab == .unscheduled ? 1 : 0)
                .allowsHitTesting(selectedTab == .unscheduled)

            timelineContent
                .opacity(selectedTab == .timeline ? 1 : 0)
                .allowsHitTesting(selectedTab == .timeline)

            AIView(viewModel: aiViewModel)
                .opacity(selectedTab == .ai ? 1 : 0)
                .allowsHitTesting(selectedTab == .ai)

            SettingsView()
                .opacity(selectedTab == .settings ? 1 : 0)
                .allowsHitTesting(selectedTab == .settings)
        }
    }

    private var timelineContent: some View {
        VStack(spacing: 0) {
            headerView
            weekStripView

            // Piano overview behind, task sheet in front
            GeometryReader { geo in
                let fullHeight = geo.size.height
                let pianoHeight: CGFloat = fullHeight - 90  // leave room for ~1 card
                let collapsedOffset: CGFloat = 0
                let expandedOffset: CGFloat = pianoHeight
                let currentOffset = pianoRevealed ? expandedOffset : collapsedOffset

                ZStack(alignment: .top) {
                    // Piano background
                    PianoWeekView(
                        weekDays: viewModel.selectedDate.weekDays,
                        tasks: allTasks,
                        selectedDate: viewModel.selectedDate
                    )
                    .frame(height: pianoHeight)
                    .opacity(pianoRevealed ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.25), value: pianoRevealed)

                    // Draggable task sheet
                    VStack(spacing: 0) {
                        // Grab handle
                        Capsule()
                            .fill(Color(.systemGray4))
                            .frame(width: 36, height: 5)
                            .padding(.top, 10)
                            .padding(.bottom, 6)

                        Divider()
                        DayTimelineView(viewModel: viewModel)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(
                        UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
                            .fill(Color(.systemGroupedBackground))
                            .shadow(color: .black.opacity(0.08), radius: 8, y: -2)
                    )
                    .offset(y: currentOffset + sheetDragOffset)
                    // Vertical drag → reveal/collapse piano
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Only track if predominantly vertical
                                if abs(value.translation.height) > abs(value.translation.width) {
                                    sheetDragOffset = value.translation.height
                                }
                            }
                            .onEnded { value in
                                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                                if isHorizontal {
                                    // YOH-91: horizontal swipe = navigate date
                                    withAnimation(.snappy(duration: 0.3)) {
                                        if value.translation.width < -50 {
                                            viewModel.goToNextDay()
                                        } else if value.translation.width > 50 {
                                            viewModel.goToPreviousDay()
                                        }
                                    }
                                } else {
                                    let threshold: CGFloat = 60
                                    withAnimation(.snappy(duration: 0.3)) {
                                        if pianoRevealed {
                                            if value.translation.height < -threshold {
                                                pianoRevealed = false
                                                Analytics.track(Analytics.Event.pianoViewToggled, properties: ["revealed": false])
                                            }
                                        } else {
                                            if value.translation.height > threshold {
                                                pianoRevealed = true
                                                Analytics.track(Analytics.Event.pianoViewToggled, properties: ["revealed": true])
                                            }
                                        }
                                        sheetDragOffset = 0
                                    }
                                }
                                sheetDragOffset = 0
                            }
                    )
                }
            }
        }
        .onChange(of: viewModel.selectedDate, initial: true) { _, date in
            DailyAnchorManager.ensureAnchors(for: date, context: modelContext)
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(alignment: .center, spacing: 10) {
            // Tab pill
            HStack(spacing: 0) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                        Analytics.track(Analytics.Event.tabSwitched, properties: ["tab": tab.title])
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .medium))
                            Text(tab.title)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(selectedTab == tab ? Color(hex: "#E8907E") : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(
                Capsule()
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 16, y: 4)
            )

            // FAB
            Button {
                showingTaskEditor = true
                Analytics.track(Analytics.Event.fabTapped, properties: ["source": selectedTab.title])
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(Color(hex: "#E8907E"))
                            .shadow(color: Color(hex: "#E8907E").opacity(0.35), radius: 8, y: 3)
                    )
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 16)
    }

    // MARK: - Timeline Header

    private var headerView: some View {
        HStack {
            Button {
                showDatePicker.toggle()
                if showDatePicker {
                    Analytics.track(Analytics.Event.datePickerOpened)
                }
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.isToday {
                        Text("Today")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: "#FF6B6B"))
                    }
                    Text(viewModel.selectedDate.fullDateString)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDatePicker) {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { viewModel.selectedDate },
                        set: { viewModel.selectDate($0) }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .presentationCompactAdaptation(.popover)
            }

            Spacer()

            HStack(spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.goToPreviousDay()
                    }
                    Analytics.track(Analytics.Event.dateNavigated, properties: ["direction": "previous"])
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }

                Button {
                    viewModel.goToToday()
                    Analytics.track(Analytics.Event.todayButtonTapped)
                } label: {
                    Text("Today")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(viewModel.isToday ? Color(.systemGray5) : Color(hex: "#FF6B6B"))
                        )
                        .foregroundStyle(viewModel.isToday ? Color.secondary : Color.white)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.goToNextDay()
                    }
                    Analytics.track(Analytics.Event.dateNavigated, properties: ["direction": "next"])
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Week Strip

    private var weekStripView: some View {
        let weekDays = viewModel.selectedDate.weekDays

        return HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectDate(day)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(day.shortDayName)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)

                        Text("\(day.dayNumber)")
                            .font(.callout.weight(day.isSameDay(as: viewModel.selectedDate) ? .bold : .regular))
                            .foregroundStyle(day.isSameDay(as: viewModel.selectedDate) ? .white
                                             : day.isToday ? Color(hex: "#FF6B6B") : .primary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(day.isSameDay(as: viewModel.selectedDate)
                                          ? Color(hex: "#FF6B6B") : .clear)
                            )

                        // Task indicator dots
                        HStack(spacing: 3) {
                            let dayColors = taskColors(for: day)
                            ForEach(dayColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 5, height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Week Strip Helpers

    /// Returns up to 3 unique task colors for a given day (for dot indicators).
    private func taskColors(for day: Date) -> [String] {
        let dayTasks = allTasks.filter {
            $0.date.isSameDay(as: day) && !$0.isInbox && !$0.isProtected && !$0.isAllDay
        }
        // Unique colors, max 3
        var seen = Set<String>()
        var colors: [String] = []
        for task in dayTasks {
            if seen.insert(task.colorHex).inserted {
                colors.append(task.colorHex)
                if colors.count >= 3 { break }
            }
        }
        return colors
    }

    // MARK: - Anchor Helpers

    private func ensureAnchorsForCurrentDate() {
        DailyAnchorManager.ensureAnchors(for: viewModel.selectedDate, context: modelContext)
    }

    // MARK: - AI Action Execution

    /// Find a task by title: exact match first, then contains-based fallback.
    private func findTask(titled title: String) -> StructuredTask? {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let exact = allTasks.first(where: {
            $0.title.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }) { return exact }
        let lower = trimmed.lowercased()
        return allTasks.first(where: {
            $0.title.lowercased().contains(lower) || lower.contains($0.title.lowercased())
        })
    }

    private func executeAIActions(_ actions: [AIAction]) {
        let cal = Calendar.current
        let today = Date()

        for action in actions {
            switch action {

            case .moveTask(let title, let hour, let minute):
                if let task = findTask(titled: title), !task.isProtected {
                    let base = task.startTime ?? task.date
                    task.startTime = cal.date(bySettingHour: hour, minute: minute, second: 0, of: base)
                }

            case .createTask(let title, let hour, let minute, let duration, let taskDate, let colorHex):
                let targetDay = (taskDate ?? today).startOfDay
                let start = cal.date(bySettingHour: hour, minute: minute, second: 0, of: targetDay)
                let newTask = StructuredTask(
                    title: title,
                    startTime: start,
                    duration: TimeInterval(duration * 60),
                    date: targetDay,
                    colorHex: colorHex ?? "#E8907E",
                    iconName: "star.fill",
                    isAllDay: false
                )
                modelContext.insert(newTask)

            case .createUnscheduledTask(let title, let duration, let colorHex):
                let newTask = StructuredTask(
                    title: title,
                    startTime: nil,
                    duration: TimeInterval(duration * 60),
                    date: today.startOfDay,
                    colorHex: colorHex ?? "#E8907E",
                    iconName: "star.fill",
                    isAllDay: false,
                    isInbox: true
                )
                modelContext.insert(newTask)

            case .completeTask(let title):
                if let task = findTask(titled: title), !task.isProtected {
                    task.isCompleted = true
                }
            }
        }

        // Force SwiftData to flush changes so @Query updates across all live views
        try? modelContext.save()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StructuredTask.self, Subtask.self], inMemory: true)
}
