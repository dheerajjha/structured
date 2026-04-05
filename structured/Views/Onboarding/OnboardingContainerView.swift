import SwiftUI
import SwiftData

struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool

    // Shared state
    @State private var wakeUpTime  = Calendar.current.date(bySettingHour: 7,  minute: 0, second: 0, of: Date())!
    @State private var bedTime     = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
    @State private var taskTitle   = ""
    @State private var taskIcon    = "envelope.fill"
    @State private var taskDuration: Double = 30
    @State private var taskColorHex = "#E8907E"

    @State private var pageIndex = 0

    // 7 pages
    private enum Page: Int, CaseIterable {
        case welcome, benefits, wakeUp, bedTime, taskEntry, taskStyle, summary
    }
    private var totalPages: Int { Page.allCases.count }

    private let warmBrown  = Color(hex: "#8B7355")
    private let accentSage = Color(hex: "#9CAF88")
    private let sageGreen  = Color(hex: "#7A9A6A")

    var body: some View {
        ZStack(alignment: .top) {
            // ── Pages ─────────────────────────────────────────────
            TabView(selection: $pageIndex) {
                OnboardingWelcomePage(onNext: { goTo(Page.benefits.rawValue) })
                    .tag(Page.welcome.rawValue)

                OnboardingBenefitsPage(onNext: { goTo(Page.wakeUp.rawValue) })
                    .tag(Page.benefits.rawValue)

                OnboardingTimePickerPage(
                    title: "When did you",
                    highlightedWord: "wake up",
                    subtitle: "Structured will help you start your day right.",
                    selectedTime: $wakeUpTime,
                    theme: .morning,
                    onContinue: { goTo(Page.bedTime.rawValue) }
                )
                .tag(Page.wakeUp.rawValue)

                OnboardingTimePickerPage(
                    title: "When will you",
                    highlightedWord: "go to bed",
                    subtitle: "Setting a clear sleep goal can help regulate your body's internal clock.",
                    selectedTime: $bedTime,
                    theme: .night,
                    onContinue: { goTo(Page.taskEntry.rawValue) }
                )
                .tag(Page.bedTime.rawValue)

                OnboardingTaskEntryPage(
                    taskTitle: $taskTitle,
                    taskIcon: $taskIcon,
                    onContinue: { goTo(Page.taskStyle.rawValue) }
                )
                .tag(Page.taskEntry.rawValue)

                OnboardingTaskStylePage(
                    taskTitle: $taskTitle,
                    taskIcon: $taskIcon,
                    duration: $taskDuration,
                    colorHex: $taskColorHex,
                    onContinue: { goTo(Page.summary.rawValue) }
                )
                .tag(Page.taskStyle.rawValue)

                OnboardingSummaryPage(
                    wakeUpTime: wakeUpTime,
                    createdTasks: summaryTasks,
                    bedTime: bedTime,
                    onFinish: { saveAndFinish() }
                )
                // Force re-render when task data changes — TabView caches pages otherwise
                .id("summary-\(taskTitle)-\(taskColorHex)-\(Int(taskDuration))")
                .tag(Page.summary.rawValue)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea()

            // ── Floating top bar ──────────────────────────────────
            topBar.padding(.top, safeTop)
        }
        .ignoresSafeArea()
    }

    // MARK: - Top Bar

    private var isIntroPage: Bool { pageIndex <= Page.benefits.rawValue }

    private var topBar: some View {
        HStack(spacing: 12) {
            // Back arrow (all pages except welcome)
            if pageIndex > 0 {
                Button { goTo(pageIndex - 1) } label: {
                    Image(systemName: "arrow.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(isIntroPage ? Color.white : warmBrown)
                        .frame(width: 36, height: 36)
                }
            }

            if isIntroPage {
                // Dot indicators — white on coral
                HStack(spacing: 8) {
                    ForEach(0..<2, id: \.self) { i in
                        Capsule()
                            .fill(Color.white.opacity(i == pageIndex ? 0.9 : 0.35))
                            .frame(width: i == pageIndex ? 20 : 7, height: 7)
                    }
                }
                Spacer()
                Button("Skip") {
                    Analytics.track(Analytics.Event.onboardingSkipped, properties: ["page_index": pageIndex])
                    finish()
                }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            } else {
                // Progress bar — setup pages
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(warmBrown.opacity(0.12))
                            .frame(height: 5)
                        Capsule()
                            .fill(pageIndex == Page.summary.rawValue ? sageGreen : accentSage)
                            .frame(width: geo.size.width * progressFraction, height: 5)
                            .animation(.easeInOut(duration: 0.3), value: pageIndex)
                    }
                }
                .frame(height: 5)

                Button("Skip") {
                    Analytics.track(Analytics.Event.onboardingSkipped, properties: ["page_index": pageIndex])
                    finish()
                }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(warmBrown.opacity(0.55))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    // MARK: - Helpers

    private var progressFraction: Double {
        let setupStart = Page.wakeUp.rawValue
        let setupEnd   = Page.summary.rawValue
        let range = Double(setupEnd - setupStart)
        let current = Double(pageIndex - setupStart)
        return range > 0 ? min(max(current / range, 0), 1) : 0
    }

    private var summaryTasks: [OnboardingTaskData] {
        guard !taskTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return [OnboardingTaskData(title: taskTitle, icon: taskIcon,
                                   colorHex: taskColorHex, durationMinutes: taskDuration)]
    }

    private var safeTop: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.top ?? 44
    }

    private func goTo(_ index: Int) {
        let clamped = min(max(index, 0), totalPages - 1)
        withAnimation(.easeInOut(duration: 0.38)) { pageIndex = clamped }
        let pageNames = ["welcome", "benefits", "wake_up", "bed_time", "task_entry", "task_style", "summary"]
        Analytics.track(Analytics.Event.onboardingPageViewed, properties: ["page": pageNames[clamped], "page_index": clamped])
    }

    private func finish() {
        withAnimation { hasCompletedOnboarding = true }
    }

    // MARK: - Save

    private func saveAndFinish() {
        let day = Date().startOfDay

        Analytics.track(Analytics.Event.onboardingCompleted, properties: [
            "wake_hour": wakeUpTime.hour,
            "bed_hour": bedTime.hour,
            "has_task": !taskTitle.trimmingCharacters(in: .whitespaces).isEmpty,
            "task_color": taskColorHex,
            "task_duration": taskDuration
        ])

        // Persist wake / bed times so DailyAnchorManager can use them going forward
        DailyAnchorManager.saveWakeTime(wakeUpTime)
        DailyAnchorManager.saveBedTime(bedTime)

        let wake = StructuredTask(
            title: "Rise and Shine",
            startTime: day.atTime(hour: wakeUpTime.hour, minute: wakeUpTime.minute),
            duration: 0, date: day, colorHex: "#E8907E",
            iconName: "sun.max.fill", isCompleted: false, order: 0,
            anchorType: AnchorType.wakeUp, isProtected: true
        )
        modelContext.insert(wake)

        if !taskTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            let start = day.atTime(hour: min(wakeUpTime.hour + 2, 22))
            let task = StructuredTask(
                title: taskTitle, startTime: start,
                duration: taskDuration * 60, date: day,
                colorHex: taskColorHex, iconName: taskIcon,
                isCompleted: false, order: 1
            )
            modelContext.insert(task)
        }

        let wind = StructuredTask(
            title: "Wind Down",
            startTime: day.atTime(hour: bedTime.hour, minute: bedTime.minute),
            duration: 0, date: day, colorHex: "#7C97AB",
            iconName: "moon.fill", isCompleted: false,
            order: summaryTasks.count + 1,
            anchorType: AnchorType.windDown, isProtected: true
        )
        modelContext.insert(wind)

        finish()
    }
}

// MARK: - Shared types

struct OnboardingTaskData {
    let title: String
    let icon: String
    let colorHex: String
    let durationMinutes: Double
}

struct OnboardingPrimaryButton: View {
    let title: String
    let colorHex: String
    var isDisabled: Bool = false
    let action: @MainActor () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: colorHex).opacity(isDisabled ? 0.4 : 1))
                )
        }
        .disabled(isDisabled)
    }
}
