import SwiftUI
import Lottie

enum TimePickerTheme {
    case morning, night

    var backgroundColor: Color {
        switch self {
        case .morning: return Color(hex: "#F5E8E0")
        case .night: return Color(hex: "#7C97AB")
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .morning: return [Color(hex: "#F5DDD0"), Color(hex: "#FFF8E7"), Color(hex: "#F5E8E0")]
        case .night: return [Color(hex: "#B8C9E0"), Color(hex: "#6B8AA8"), Color(hex: "#4A6E8A")]
        }
    }

    var accentColor: Color {
        switch self {
        case .morning: return Color(hex: "#E8907E")
        case .night: return Color(hex: "#F5F0E0")
        }
    }

    var pillBackgroundColor: Color {
        switch self {
        case .morning: return Color(hex: "#E8907E")
        case .night: return .white
        }
    }

    var pillTextColor: Color {
        switch self {
        case .morning: return .white
        case .night: return Color(hex: "#4A6E8A")
        }
    }

    var buttonColor: String {
        switch self {
        case .morning: return "#E8907E"
        case .night: return "#7C97AB"
        }
    }

    var icon: String {
        switch self {
        case .morning: return "alarm.fill"
        case .night: return "moon.fill"
        }
    }
}

/// Reusable time picker page — used for wake-up and bedtime
struct OnboardingTimePickerPage: View {
    let title: String
    let highlightedWord: String
    let subtitle: String
    @Binding var selectedTime: Date
    let theme: TimePickerTheme
    var onContinue: (@MainActor () -> Void)? = nil

    @State private var scrollPositionID: Int?

    private let intervalMinutes = 15

    private var timeSlots: [Date] {
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        return stride(from: 0, to: 24 * 60, by: intervalMinutes).compactMap {
            calendar.date(byAdding: .minute, value: $0, to: baseDate)
        }
    }

    private var selectedIndex: Int {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: selectedTime)
        let minute = calendar.component(.minute, from: selectedTime)
        let totalMinutes = hour * 60 + minute
        return totalMinutes / intervalMinutes
    }

    var body: some View {
        ZStack {
            // Full-screen background for each theme
            switch theme {
            case .morning:
                Color(hex: "#FAF0E8").ignoresSafeArea()
            case .night:
                LinearGradient(
                    colors: [Color(hex: "#8FA8BE"), Color(hex: "#5C7A96")],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            VStack(alignment: .leading, spacing: 0) {
            // Clear floating topBar
            Spacer().frame(height: scaled(80))

            // Title
            VStack(alignment: .leading, spacing: scaled(8)) {
                (Text(title + " ")
                    .font(.system(size: scaled(32), weight: .bold))
                    .foregroundStyle(theme == .night ? .white : .primary)
                 +
                 Text(highlightedWord)
                    .font(.system(size: scaled(32), weight: .bold))
                    .foregroundStyle(theme.accentColor)
                 +
                 Text("?")
                    .font(.system(size: scaled(32), weight: .bold))
                    .foregroundStyle(theme == .night ? .white : .primary)
                )

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(theme == .night ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, scaled(24))
            .padding(.top, scaled(8))

            Spacer()

            // Time picker area with background
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: scaled(24))
                    .fill(
                        LinearGradient(
                            colors: theme.gradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.horizontal, scaled(16))

                VStack(spacing: 0) {
                    // Decorative icon
                    themeIcon
                        .padding(.bottom, scaled(8))

                    // Up arrow
                    Image(systemName: "chevron.up")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(theme == .night ? .white.opacity(0.6) : .secondary)
                        .padding(.bottom, scaled(8))

                    // Time list
                    timeListView

                    // Down arrow
                    Image(systemName: "chevron.down")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(theme == .night ? .white.opacity(0.6) : .secondary)
                        .padding(.top, scaled(8))
                }
                .padding(.vertical, scaled(16))
            }
            .frame(height: scaled(340))

            Spacer()

            // Continue button embedded in page — no z-fighting
            if let onContinue {
                Button {
                    // Commit scroll position to selectedTime before continuing
                    if let idx = scrollPositionID, idx >= 0, idx < timeSlots.count {
                        selectedTime = timeSlots[idx]
                    }
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: scaled(56))
                        .background(
                            RoundedRectangle(cornerRadius: scaled(28))
                                .fill(Color(hex: theme.buttonColor))
                        )
                }
                .padding(.horizontal, scaled(24))
                .padding(.bottom, scaled(32))
            }
            } // VStack
        } // ZStack
    }

    // MARK: - Theme Icon

    @ViewBuilder
    private var themeIcon: some View {
        switch theme {
        case .morning:
            LottieView {
                try await DotLottieFile.named("sun")
            }
            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
            .frame(width: scaled(100), height: scaled(100))

        case .night:
            LottieView {
                try await DotLottieFile.named("moon")
            }
            .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
            .frame(width: scaled(80), height: scaled(80))
        }
    }

    // MARK: - Time List

    private var timeListView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(spacing: scaled(4)) {
                ForEach(Array(timeSlots.enumerated()), id: \.offset) { index, time in
                    let isSelected = index == selectedIndex
                    let distance = abs(index - selectedIndex)

                    timeSlotButton(time: time, index: index, isSelected: isSelected, distance: distance)
                        .id(index)
                }
            }
            .padding(.vertical, scaled(40))
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollPositionID, anchor: .center)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .frame(height: scaled(220))
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .white, location: 0.2),
                    .init(color: .white, location: 0.8),
                    .init(color: .clear, location: 1.0),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            scrollPositionID = selectedIndex
        }
        .onScrollPhaseChange { _, newPhase in
            // Only commit selection when scroll fully stops — no state changes during scrolling
            if newPhase == .idle, let id = scrollPositionID, id >= 0, id < timeSlots.count {
                selectedTime = timeSlots[id]
            }
        }
    }
    // MARK: - Time Slot Button (extracted to help type checker)

    private func timeSlotButton(time: Date, index: Int, isSelected: Bool, distance: Int) -> some View {
        let textOpacity: Double = isSelected ? 1.0 : max(1.0 - Double(distance) * 0.25, 0.25)
        let baseColor: Color = theme == .night ? .white : .primary

        return Button {
            selectedTime = time
            scrollPositionID = index
        } label: {
            Text(TimeFormatting.timeString(from: time))
                .font(.system(size: scaled(18), weight: .semibold))
                .foregroundStyle(isSelected ? theme.pillTextColor : baseColor.opacity(textOpacity))
                .frame(width: scaled(160), height: scaled(40))
                .background(
                    Capsule().fill(isSelected ? theme.pillBackgroundColor : .clear)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview("Morning") {
    OnboardingTimePickerPage(
        title: "When did you",
        highlightedWord: "wake up",
        subtitle: "Tickd will help you start your day right.",
        selectedTime: .constant(Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!),
        theme: .morning,
        onContinue: {}
    )
}

#Preview("Night") {
    OnboardingTimePickerPage(
        title: "When will you",
        highlightedWord: "go to bed",
        subtitle: "Setting a clear sleep goal can help to regulate your body's internal clock.",
        selectedTime: .constant(Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!),
        theme: .night,
        onContinue: {}
    )
}
