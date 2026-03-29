import SwiftUI

/// Page 8: "What color?" — color picker with task preview
struct OnboardingColorPage: View {
    let taskTitle: String
    let taskIcon: String
    let duration: Double
    @Binding var selectedColorHex: String

    private let colors: [(hex: String, name: String)] = [
        ("#E8907E", "Coral"),
        ("#E8A87C", "Peach"),
        ("#D4A843", "Gold"),
        ("#8FB872", "Green"),
        ("#7C97AB", "Blue"),
        ("#4A7C6F", "Teal"),
        ("#9B8AA8", "Mauve"),
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
        ZStack {
            // Decorative background scribbles
            decorativeBackground

            VStack(alignment: .leading, spacing: 0) {
                // Title
                VStack(alignment: .leading, spacing: 8) {
                    (Text("What ")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                     +
                     Text("color")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Color(hex: selectedColorHex))
                     +
                     Text("?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                    )

                    Text("Pick a color for your task.")
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

                // Color circles
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(colors, id: \.hex) { color in
                            Button {
                                withAnimation(.snappy(duration: 0.25)) {
                                    selectedColorHex = color.hex
                                }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: color.hex))
                                        .frame(width: 48, height: 48)

                                    if selectedColorHex == color.hex {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 3)
                                            .frame(width: 48, height: 48)

                                        Circle()
                                            .strokeBorder(Color(hex: color.hex).opacity(0.5), lineWidth: 1)
                                            .frame(width: 54, height: 54)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.white.opacity(0.8))
                        .padding(.horizontal, 16)
                )

                Spacer()
                Spacer()
            }
        }
    }

    private var taskPreviewCard: some View {
        HStack(spacing: 12) {
            TaskIconView(iconName: taskIcon, colorHex: selectedColorHex, size: 44)

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
                .foregroundStyle(Color(hex: selectedColorHex).opacity(0.4))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white)
                .shadow(color: .black.opacity(0.04), radius: 6, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(hex: selectedColorHex).opacity(0.3), lineWidth: 1.5)
        )
    }

    private var decorativeBackground: some View {
        ZStack {
            // Scribble marks in background (like the original)
            ForEach(0..<6, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: colors[i % colors.count].hex).opacity(0.12))
                    .frame(width: CGFloat.random(in: 60...120), height: CGFloat.random(in: 60...120))
                    .rotationEffect(.degrees(Double.random(in: -30...30)))
                    .offset(
                        x: CGFloat([-120, 130, -100, 140, -60, 100][i]),
                        y: CGFloat([200, -50, 350, 400, 100, 300][i])
                    )
            }
        }
    }
}

#Preview {
    OnboardingColorPage(
        taskTitle: "Answer Emails",
        taskIcon: "envelope.fill",
        duration: 15,
        selectedColorHex: .constant("#8FB872")
    )
}
