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

    @State private var selectedMinuteOffset = 0

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
        VStack(alignment: .leading, spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                (Text(title + " ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(theme == .night ? .white : .primary)
                 +
                 Text(highlightedWord)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(theme.accentColor)
                 +
                 Text("?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(theme == .night ? .white : .primary)
                )

                Text(subtitle)
                    .font(.body)
                    .foregroundStyle(theme == .night ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            // Time picker area with background
            ZStack {
                // Gradient background
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        LinearGradient(
                            colors: theme.gradientColors,
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    // Decorative icon
                    themeIcon
                        .padding(.bottom, 8)

                    // Up arrow
                    Image(systemName: "chevron.up")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(theme == .night ? .white.opacity(0.6) : .secondary)
                        .padding(.bottom, 8)

                    // Time list
                    timeListView

                    // Down arrow
                    Image(systemName: "chevron.down")
                        .font(.title3.weight(.medium))
                        .foregroundStyle(theme == .night ? .white.opacity(0.6) : .secondary)
                        .padding(.top, 8)
                }
                .padding(.vertical, 16)
            }
            .frame(height: 380)

            Spacer()
        }
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
                    .frame(width: 60, height: 60)

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(Color(hex: "#F5D547"))
            }

        case .night:
            // Moon
            ZStack {
                Image(systemName: "moon.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color(hex: "#F5E0A0"))

                // Stars
                ForEach(0..<5, id: \.self) { i in
                    Circle()
                        .fill(Color(hex: "#F5E0A0").opacity(0.6))
                        .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                        .offset(
                            x: CGFloat([-40, 30, -20, 50, -10][i]),
                            y: CGFloat([-15, -25, 20, 10, -30][i])
                        )
                }
            }
        }
    }

    // MARK: - Time List

    private var timeListView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(Array(timeSlots.enumerated()), id: \.offset) { index, time in
                        let isSelected = index == selectedIndex
                        let distance = abs(index - selectedIndex)

                        timeSlotButton(time: time, index: index, isSelected: isSelected, distance: distance)
                            .id(index)
                    }
                }
                .padding(.vertical, 40)
            }
            .frame(height: 220)
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
                proxy.scrollTo(selectedIndex, anchor: .center)
            }
        }
    }
    // MARK: - Time Slot Button (extracted to help type checker)

    private func timeSlotButton(time: Date, index: Int, isSelected: Bool, distance: Int) -> some View {
        let fontSize: CGFloat = isSelected ? 20 : max(16 - CGFloat(distance) * 1.5, 12)
        let fontWeight: Font.Weight = isSelected ? .bold : .regular
        let textOpacity: Double = isSelected ? 1.0 : max(1.0 - Double(distance) * 0.2, 0.3)
        let textColor: Color = isSelected ? theme.pillTextColor : (theme == .night ? Color.white.opacity(textOpacity) : Color.primary.opacity(textOpacity))

        return Button {
            withAnimation(.snappy(duration: 0.3)) {
                selectedTime = time
            }
        } label: {
            HStack(spacing: 8) {
                if isSelected {
                    Image(systemName: theme.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(theme.pillTextColor)
                }

                Text(TimeFormatting.timeString(from: time))
                    .font(.system(size: fontSize, weight: fontWeight))
                    .foregroundStyle(textColor)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
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
        subtitle: "Structured will help you start your day right.",
        selectedTime: .constant(Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!),
        theme: .morning
    )
}

#Preview("Night") {
    OnboardingTimePickerPage(
        title: "When will you",
        highlightedWord: "go to bed",
        subtitle: "Setting a clear sleep goal can help to regulate your body's internal clock.",
        selectedTime: .constant(Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!),
        theme: .night
    )
}
