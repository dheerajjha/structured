import SwiftUI

/// Page 9: "Awesome! That's a great plan." with task timeline summary
struct OnboardingSummaryPage: View {
    let wakeUpTime: Date
    let createdTasks: [OnboardingTaskData]
    let bedTime: Date

    private let greenColor = Color(hex: "#7CB342")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                (Text("Awesome! ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(greenColor)
                 +
                 Text("That's a great plan.")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                )

                Text("You're all set! It's time to achieve your goals.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Plan label
            Text("Your Structured Plan:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .padding(.top, 32)

            // Task timeline
            taskTimeline
                .padding(.horizontal, 24)
                .padding(.top, 12)

            Spacer()
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

            // User-created tasks
            ForEach(Array(createdTasks.enumerated()), id: \.offset) { index, task in
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
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
        HStack(spacing: 14) {
            // Icon + connector line
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color(hex: colorHex))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                }

                if !isLast {
                    // Dotted connector line
                    DottedLine()
                        .stroke(Color(hex: nextColorHex).opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                        .frame(width: 2, height: 24)
                }
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
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
                size: 24
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
        createdTasks: [
            OnboardingTaskData(title: "Answer Emails", icon: "envelope.fill", colorHex: "#8FB872", durationMinutes: 15),
        ],
        bedTime: Calendar.current.date(bySettingHour: 22, minute: 0, second: 0, of: Date())!
    )
}
