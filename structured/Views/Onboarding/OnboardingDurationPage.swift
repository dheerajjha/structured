import SwiftUI

/// Page 7: "How long?" — duration picker
struct OnboardingDurationPage: View {
    let taskTitle: String
    let taskIcon: String
    let taskColorHex: String
    @Binding var duration: Double

    private let coralColor = Color(hex: "#E8907E")

    private let options: [(label: String, minutes: Double)] = [
        ("1", 1),
        ("15m", 15),
        ("30", 30),
        ("45", 45),
        ("1h", 60),
        ("1.5h", 90),
    ]

    private var previewTimeRange: String {
        let calendar = Calendar.current
        let now = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let end = now.addingTimeInterval(duration * 60)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "h:mm a"
        let durationStr: String
        if duration >= 60 {
            let hrs = Int(duration) / 60
            let mins = Int(duration) % 60
            durationStr = mins > 0 ? "\(hrs) hr \(mins) min" : "\(hrs) hr"
        } else {
            durationStr = "\(Int(duration)) min"
        }
        return "\(formatter.string(from: now)) – \(endFormatter.string(from: end)) (\(durationStr))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                (Text("How ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                 +
                 Text("long")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(coralColor)
                 +
                 Text("?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                )

                Text("Set a duration for your task.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            // Task preview card
            taskPreviewCard
                .padding(.horizontal, 24)
                .padding(.top, 32)

            Spacer()

            // Duration pills
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    ForEach(options, id: \.minutes) { option in
                        Button {
                            withAnimation(.snappy(duration: 0.2)) {
                                duration = option.minutes
                            }
                        } label: {
                            Text(option.label)
                                .font(.body.weight(duration == option.minutes ? .bold : .regular))
                                .foregroundStyle(duration == option.minutes ? .white : .secondary)
                                .frame(width: 50, height: 44)
                                .background(
                                    Capsule()
                                        .fill(duration == option.minutes ? coralColor : .clear)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
                .background(
                    Capsule()
                        .fill(Color(.systemGray6))
                )

                Button {
                    // Could show custom duration picker
                } label: {
                    Text("Need a different duration?")
                        .font(.subheadline)
                        .foregroundStyle(coralColor)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()
            Spacer()
        }
    }

    private var taskPreviewCard: some View {
        HStack(spacing: 12) {
            TaskIconView(iconName: taskIcon, colorHex: taskColorHex, size: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(previewTimeRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(taskTitle)
                    .font(.subheadline.weight(.semibold))
            }

            Spacer()

            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundStyle(Color(hex: taskColorHex).opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(hex: taskColorHex).opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    OnboardingDurationPage(
        taskTitle: "Answer Emails",
        taskIcon: "envelope.fill",
        taskColorHex: "#E8907E",
        duration: .constant(15)
    )
}
