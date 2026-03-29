import SwiftUI
import SwiftData

/// Main onboarding container — manages navigation between all onboarding pages
struct OnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var hasCompletedOnboarding: Bool

    @State private var currentPage: OnboardingPage = .welcome
    @State private var planForToday = true
    @State private var wakeUpTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @State private var bedTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!
    @State private var taskTitle = ""
    @State private var taskIcon = "envelope.fill"
    @State private var taskDuration: Double = 15
    @State private var taskColorHex = "#E8907E"
    @State private var createdTasks: [OnboardingTaskData] = []

    enum OnboardingPage: Int, CaseIterable {
        case welcome, benefits, getStarted, wakeUp, bedTime, taskEntry, duration, color, summary
    }

    // MARK: - Progress

    /// Pages after getStarted use a progress bar
    private var usesProgressBar: Bool {
        currentPage.rawValue >= OnboardingPage.getStarted.rawValue
    }

    private var progressFraction: Double {
        let setupPages: [OnboardingPage] = [.getStarted, .wakeUp, .bedTime, .taskEntry, .duration, .color, .summary]
        guard let idx = setupPages.firstIndex(of: currentPage) else { return 0 }
        return Double(idx + 1) / Double(setupPages.count)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            topBar

            // Page content
            Group {
                switch currentPage {
                case .welcome:
                    OnboardingWelcomePage()
                case .benefits:
                    OnboardingBenefitsPage()
                case .getStarted:
                    OnboardingGetStartedPage(planForToday: $planForToday)
                case .wakeUp:
                    OnboardingTimePickerPage(
                        title: "When did you",
                        highlightedWord: "wake up",
                        subtitle: "Structured will help you start your day right.",
                        selectedTime: $wakeUpTime,
                        theme: .morning
                    )
                case .bedTime:
                    OnboardingTimePickerPage(
                        title: "When will you",
                        highlightedWord: "go to bed",
                        subtitle: "Setting a clear sleep goal can help to regulate your body's internal clock.",
                        selectedTime: $bedTime,
                        theme: .night
                    )
                case .taskEntry:
                    OnboardingTaskEntryPage(
                        taskTitle: $taskTitle,
                        taskIcon: $taskIcon
                    )
                case .duration:
                    OnboardingDurationPage(
                        taskTitle: taskTitle,
                        taskIcon: taskIcon,
                        taskColorHex: taskColorHex,
                        duration: $taskDuration
                    )
                case .color:
                    OnboardingColorPage(
                        taskTitle: taskTitle,
                        taskIcon: taskIcon,
                        duration: taskDuration,
                        selectedColorHex: $taskColorHex
                    )
                case .summary:
                    OnboardingSummaryPage(
                        wakeUpTime: wakeUpTime,
                        createdTasks: createdTasks,
                        bedTime: bedTime
                    )
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            Spacer(minLength: 0)

            // Bottom action
            bottomAction
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            if currentPage.rawValue > OnboardingPage.getStarted.rawValue - 1 && currentPage != .welcome {
                Button {
                    goBack()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }

            if usesProgressBar {
                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray4))
                            .frame(height: 6)

                        Capsule()
                            .fill(Color(hex: currentPage == .summary ? "#7CB342" : "#E8907E"))
                            .frame(width: geo.size.width * progressFraction, height: 6)
                            .animation(.easeInOut(duration: 0.3), value: progressFraction)
                    }
                }
                .frame(height: 6)
            } else {
                // Page dots
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage.rawValue ? Color(hex: "#E8907E") : Color(hex: "#E8907E").opacity(0.4))
                            .frame(width: index == currentPage.rawValue ? 20 : 8, height: 8)
                    }
                }
                Spacer()
            }

            Button("Skip") {
                finishOnboarding()
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.primary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Bottom Action

    @ViewBuilder
    private var bottomAction: some View {
        switch currentPage {
        case .welcome, .benefits:
            HStack {
                Spacer()
                Button {
                    goNext()
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.primary.opacity(0.6))
                        .frame(width: 56, height: 56)
                        .background(
                            Circle()
                                .fill(Color(.systemGray5))
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

        case .getStarted:
            VStack(spacing: 12) {
                Button {
                    planForToday.toggle()
                } label: {
                    Text(planForToday ? "Plan for tomorrow instead" : "Plan for today instead")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                OnboardingPrimaryButton(
                    title: "Start Planning",
                    colorHex: "#E8907E"
                ) {
                    goNext()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

        case .wakeUp, .bedTime:
            OnboardingPrimaryButton(
                title: "Continue",
                colorHex: currentPage == .bedTime ? "#7C97AB" : "#E8907E"
            ) {
                goNext()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

        case .taskEntry:
            OnboardingPrimaryButton(
                title: "Continue",
                colorHex: "#E8907E",
                isDisabled: taskTitle.trimmingCharacters(in: .whitespaces).isEmpty
            ) {
                goNext()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

        case .duration, .color:
            OnboardingPrimaryButton(
                title: "Continue",
                colorHex: currentPage == .color ? taskColorHex : "#E8907E"
            ) {
                if currentPage == .color {
                    // Save the created task data and go to summary
                    let taskData = OnboardingTaskData(
                        title: taskTitle,
                        icon: taskIcon,
                        colorHex: taskColorHex,
                        durationMinutes: taskDuration
                    )
                    createdTasks.append(taskData)
                }
                goNext()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)

        case .summary:
            OnboardingPrimaryButton(
                title: "Finish Setup",
                colorHex: "#7CB342"
            ) {
                saveOnboardingData()
                finishOnboarding()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Navigation

    private func goNext() {
        let allPages = OnboardingPage.allCases
        guard let idx = allPages.firstIndex(of: currentPage),
              idx + 1 < allPages.count else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentPage = allPages[idx + 1]
        }
    }

    private func goBack() {
        let allPages = OnboardingPage.allCases
        guard let idx = allPages.firstIndex(of: currentPage), idx > 0 else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            currentPage = allPages[idx - 1]
        }
    }

    // MARK: - Save & Finish

    private func saveOnboardingData() {
        let targetDate = planForToday ? Date().startOfDay : Date().nextDay.startOfDay

        // Create wake-up task
        let wakeTask = StructuredTask(
            title: "Rise and Shine",
            startTime: targetDate.atTime(hour: wakeUpTime.hour, minute: wakeUpTime.minute),
            duration: 0,
            date: targetDate,
            colorHex: "#E8907E",
            iconName: "sun.max.fill",
            isCompleted: false,
            order: 0
        )
        modelContext.insert(wakeTask)

        // Create user tasks
        for (index, taskData) in createdTasks.enumerated() {
            // Place tasks after wake up, spaced out
            let startHour = wakeUpTime.hour + 2 + index * 2
            let start = targetDate.atTime(hour: min(startHour, 22))
            let task = StructuredTask(
                title: taskData.title,
                startTime: start,
                duration: taskData.durationMinutes * 60,
                date: targetDate,
                colorHex: taskData.colorHex,
                iconName: taskData.icon,
                isCompleted: false,
                order: index + 1
            )
            modelContext.insert(task)
        }

        // Create wind-down task
        let windDown = StructuredTask(
            title: "Wind Down",
            startTime: targetDate.atTime(hour: bedTime.hour, minute: bedTime.minute),
            duration: 0,
            date: targetDate,
            colorHex: "#7C97AB",
            iconName: "moon.fill",
            isCompleted: false,
            order: createdTasks.count + 1
        )
        modelContext.insert(windDown)
    }

    private func finishOnboarding() {
        withAnimation(.easeInOut(duration: 0.4)) {
            hasCompletedOnboarding = true
        }
    }
}

// MARK: - Supporting Types

struct OnboardingTaskData {
    let title: String
    let icon: String
    let colorHex: String
    let durationMinutes: Double
}

// MARK: - Reusable Primary Button

struct OnboardingPrimaryButton: View {
    let title: String
    let colorHex: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color(hex: colorHex).opacity(isDisabled ? 0.4 : 1.0))
                )
        }
        .disabled(isDisabled)
    }
}
