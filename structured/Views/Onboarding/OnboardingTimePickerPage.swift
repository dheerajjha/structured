import SwiftUI

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

    @State private var selectedMinuteOffset = 0
    @State private var scrollPositionID: Int?

    private let intervalMinutes = 15
    private var timeSlots: [Date] {
        var slots: [Date] = []
        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: Date())
        for minuteOffset in stride(from: 0, to: 24 * 60, by: intervalMinutes) {
            if let date = calendar.date(byAdding: .minute, value: minuteOffset, to: baseDate) {
                slots.append(date)
            }
        }
        return slots
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
                Button(action: onContinue) {
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
            // Sun
            ZStack {
                Circle()
                    .fill(Color(hex: "#F5D547").opacity(0.8))
                    .frame(width: scaled(60), height: scaled(60))

                Image(systemName: "sun.max.fill")
                    .font(.system(size: scaled(30)))
                    .foregroundStyle(Color(hex: "#F5D547"))
            }

        case .night:
            // Moon
            ZStack {
                Image(systemName: "moon.fill")
                    .font(.system(size: scaled(44)))
                    .foregroundStyle(Color(hex: "#F5E0A0"))

                // Stars
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "#F5E0A0").opacity(0.6))
                        .frame(width: CGFloat.random(in: scaled(2)...scaled(4)), height: CGFloat.random(in: scaled(2)...scaled(4)))
                        .offset(
                            x: scaled(CGFloat([-40, 30, -20, 50, -10][i])),
                            y: scaled(CGFloat([-15, -25, 20, 10, -30][i]))
                        )
                }
            }
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
        // Real-time update as user scrolls (YOH-89)
        .onChange(of: scrollPositionID) { _, id in
            guard let id, id < timeSlots.count else { return }
            selectedTime = timeSlots[id]
        }
        // When selection changes from a tap, scroll to it
        .onChange(of: selectedIndex) { _, newIndex in
            scrollPositionID = newIndex
        }
    }
    // MARK: - Time Slot Button (extracted to help type checker)

    private func timeSlotButton(time: Date, index: Int, isSelected: Bool, distance: Int) -> some View {
        let fontSize: CGFloat = isSelected ? scaled(20) : max(scaled(16) - CGFloat(distance) * scaled(1.5), scaled(12))
        let fontWeight: Font.Weight = isSelected ? .bold : .regular
        let textOpacity: Double = isSelected ? 1.0 : max(1.0 - Double(distance) * 0.2, 0.3)
        let textColor: Color = isSelected ? theme.pillTextColor : (theme == .night ? Color.white.opacity(textOpacity) : Color.primary.opacity(textOpacity))

        return Button {
            withAnimation(.snappy(duration: 0.3)) {
                selectedTime = time
                scrollPositionID = index
            }
        } label: {
            HStack(spacing: scaled(8)) {
                if isSelected {
                    Image(systemName: theme.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.pillTextColor)
                }

                Text(TimeFormatting.timeString(from: time))
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundStyle(textColor)
            }
            .padding(.horizontal, scaled(24))
            .padding(.vertical, scaled(10))
            .background {
                if isSelected {
                    Capsule().fill(theme.pillBackgroundColor)
                }
            }
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
