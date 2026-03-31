import SwiftUI
import SwiftData

// MARK: - App Tabs

enum AppTab: CaseIterable {
    case unscheduled, timeline, ai, settings

    var title: String {
        switch self {
        case .unscheduled: return "Unscheduled"
        case .timeline:    return "Timeline"
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
    @State private var showingTaskEditor = false
    @State private var showDatePicker = false

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
        }
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .unscheduled:
            InboxView()
        case .timeline:
            VStack(spacing: 0) {
                headerView
                weekStripView
                Divider()
                DayTimelineView(viewModel: viewModel)
            }
            .onChange(of: viewModel.selectedDate, initial: true) { _, date in
                DailyAnchorManager.ensureAnchors(for: date, context: modelContext)
            }
        case .ai:
            AIView(viewModel: aiViewModel)
        case .settings:
            SettingsView()
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
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 20, weight: .medium))
                            Text(tab.title)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(selectedTab == tab ? Color(hex: "#E8907E") : Color.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
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
        .padding(.bottom, 28)
    }

    // MARK: - Timeline Header

    private var headerView: some View {
        HStack {
            Button {
                showDatePicker.toggle()
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
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }

                Button {
                    viewModel.goToToday()
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
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Anchor Helpers

    private func ensureAnchorsForCurrentDate() {
        DailyAnchorManager.ensureAnchors(for: viewModel.selectedDate, context: modelContext)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StructuredTask.self, Subtask.self], inMemory: true)
}
