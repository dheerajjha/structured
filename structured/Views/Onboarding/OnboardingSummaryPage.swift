import SwiftUI

/// Page 9: "Awesome! That's a great plan." with task timeline summary
struct OnboardingSummaryPage: View {
    let wakeUpTime: Date
    @Binding var createdTasks: [OnboardingTaskData]
    let bedTime: Date
    var onFinish: (@MainActor () -> Void)? = nil

    private let greenColor = Color(hex: "#7CB342")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Clear the floating topBar
            Spacer().frame(height: scaled(80))

            // Title
            VStack(alignment: .leading, spacing: scaled(8)) {
                (Text("Awesome! ")
                    .font(.system(size: scaled(32), weight: .bold))
                    .foregroundStyle(greenColor)
                 +
                 Text("That's a great plan.")
                    .font(.system(size: scaled(32), weight: .bold))
                    .foregroundStyle(.primary)
                )

                Text("You're all set! It's time to achieve your goals.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, scaled(24))
            .padding(.top, scaled(4))

            // Plan label
            Text("Your Tickd Plan:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, scaled(24))
                .padding(.top, scaled(32))

            // Task timeline
            taskTimeline
                .padding(.horizontal, scaled(24))
                .padding(.top, scaled(12))

            Spacer()

            if let onFinish {
                OnboardingPrimaryButton(title: "Finish Setup", colorHex: "#7A9A6A", action: onFinish)
                    .padding(.horizontal, scaled(24))
                    .padding(.bottom, scaled(32))
            }
        }
    }

    private var taskTimeline: some View {
        VStack(spacing: 0) {
            // Wake up task
            timelineRow(
                icon: "sun.max.fill",
                colorHex: "#E8907E",
                title: "Rise and Shine",
                timeStr: TimeFormatting.timeString(from: wakeUpTime),
                isCompleted: true,
                isLast: false,
                nextColorHex: createdTasks.first?.colorHex ?? "#7C97AB"
            )

            // User-created task
            if let firstTask = createdTasks.first {
                userTaskRow(task: firstTask, index: 0)
            }

            // Bedtime task
            timelineRow(
                icon: "moon.fill",
                colorHex: "#7C97AB",
                title: "Wind Down",
                timeStr: TimeFormatting.timeString(from: bedTime),
                isCompleted: false,
                isLast: true,
                nextColorHex: ""
            )
        }
        .padding(scaled(20))
        .background(
            RoundedRectangle(cornerRadius: scaled(16))
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: scaled(8), y: scaled(2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: scaled(16))
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func userTaskRow(task: OnboardingTaskData, index: Int) -> some View {
        let startHour = wakeUpTime.hour + 2 + index * 2
        let startDate = Date().atTime(hour: min(startHour, 22))
        let endDate = startDate.addingTimeInterval(task.durationMinutes * 60)
        let durationStr: String = {
            if task.durationMinutes >= 60 {
                let hrs = Int(task.durationMinutes) / 60
                let mins = Int(task.durationMinutes) % 60
                return mins > 0 ? "\(hrs) hr \(mins) min" : "\(hrs) hr"
            }
            return "\(Int(task.durationMinutes)) min"
        }()

        timelineRow(
            icon: task.icon,
            colorHex: task.colorHex,
            title: task.title,
            timeStr: "\(TimeFormatting.timeString(from: startDate)) – \(TimeFormatting.timeString(from: endDate)) (\(durationStr))",
            isCompleted: false,
            isLast: false,
            nextColorHex: index == createdTasks.count - 1 ? "#7C97AB" : createdTasks[index + 1].colorHex
        )
    }

    private func timelineRow(
        icon: String,
        colorHex: String,
        title: String,
        timeStr: String,
        isCompleted: Bool,
        isLast: Bool,
        nextColorHex: String
    ) -> some View {
        HStack(spacing: scaled(14)) {
            // Icon + connector line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: scaled(40), height: scaled(40))

                    Image(systemName: icon)
                        .font(.system(size: scaled(16), weight: .semibold))
                        .foregroundStyle(.white)
                }

                if !isLast {
                    // Dotted connector line
                    DottedLine()
                        .stroke(Color(hex: nextColorHex).opacity(0.4), style: StrokeStyle(lineWidth: scaled(2), dash: [scaled(4), scaled(3)]))
                        .frame(width: scaled(2), height: scaled(24))
                }
            }

            // Text
            VStack(alignment: .leading, spacing: scaled(2)) {
                Text(timeStr)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isCompleted ? .secondary : .primary)
                    .strikethrough(isCompleted)
            }

            Spacer()

            // Completion circle
            CompletionCircleView(
                isCompleted: isCompleted,
                colorHex: colorHex,
                size: scaled(24)
            )
        }
    }
}

// MARK: - Dotted Line Shape

struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

#Preview {
    OnboardingSummaryPage(
        wakeUpTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
        createdTasks: .constant([
            OnboardingTaskData(title: "Answer Emails", icon: "envelope.fill", colorHex: "#8FB872", durationMinutes: 15),
        ]),
        bedTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
    )
}
