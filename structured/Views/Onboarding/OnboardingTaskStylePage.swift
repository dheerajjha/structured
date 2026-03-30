import SwiftUI

/// Page 6: Duration + Color on one screen — "How long, and what color?"
struct OnboardingTaskStylePage: View {
    @Binding var taskTitle: String
    @Binding var taskIcon: String
    @Binding var duration: Double
    @Binding var colorHex: String
    var onContinue: (@MainActor () -> Void)? = nil

    private let coral = Color(hex: "#D4806E")
    private let warmBrown = Color(hex: "#8B7355")

    private let durations: [(label: String, mins: Double)] = [
        ("5m", 5), ("15m", 15), ("30m", 30),
        ("45m", 45), ("1h", 60), ("1.5h", 90), ("2h", 120),
    ]

    private let colors: [String] = [
        "#E8907E", "#E8A87C", "#D4A843",
        "#8FB872", "#7C97AB", "#4A7C6F", "#9B8AA8",
    ]

    private var previewRange: String {
        let start = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
        let end   = start.addingTimeInterval(duration * 60)
        let fmt   = DateFormatter()
        fmt.dateFormat = "h:mm"
        let fmtEnd = DateFormatter()
        fmtEnd.dateFormat = "h:mm a"
        let d = duration >= 60
            ? (duration.truncatingRemainder(dividingBy: 60) == 0
               ? "\(Int(duration/60)) hr"
               : "\(Int(duration/60)) hr \(Int(duration.truncatingRemainder(dividingBy: 60))) min")
            : "\(Int(duration)) min"
        return "\(fmt.string(from: start)) – \(fmtEnd.string(from: end)) (\(d))"
    }

    var body: some View {
        ZStack {
            // Subtle colored scribbles in bg
            decorativeBg
            Color(hex: "#F5F0EB").ignoresSafeArea()
            decorativeBg

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 80)

                // Title
                VStack(alignment: .leading, spacing: 6) {
                    (Text("How ")
                        .foregroundStyle(Color(hex: "#3D3D3D"))
                     + Text("long")
                        .foregroundStyle(coral)
                     + Text(", and what ")
                        .foregroundStyle(Color(hex: "#3D3D3D"))
                     + Text("color")
                        .foregroundStyle(Color(hex: colorHex))
                     + Text("?")
                        .foregroundStyle(Color(hex: "#3D3D3D"))
                    )
                    .font(.system(size: 28, weight: .bold))

                    Text("Set a duration and pick a color for your task.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                // Task preview card
                taskCard.padding(.horizontal, 24)

                Spacer().frame(height: 36)

                // Duration pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(durations, id: \.mins) { opt in
                            Button {
                                withAnimation(.snappy(duration: 0.2)) { duration = opt.mins }
                            } label: {
                                Text(opt.label)
                                    .font(.subheadline.weight(duration == opt.mins ? .bold : .medium))
                                    .foregroundStyle(duration == opt.mins ? .white : Color(hex: "#8B7355"))
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule().fill(duration == opt.mins ? coral : Color(.systemGray6))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer().frame(height: 28)

                // Color circles
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(colors, id: \.self) { c in
                            Button {
                                withAnimation(.snappy(duration: 0.25)) { colorHex = c }
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: c))
                                        .frame(width: 44, height: 44)
                                    if colorHex == c {
                                        Circle()
                                            .strokeBorder(.white, lineWidth: 3)
                                            .frame(width: 44, height: 44)
                                        Circle()
                                            .strokeBorder(Color(hex: c).opacity(0.5), lineWidth: 1)
                                            .frame(width: 50, height: 50)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }

                Spacer()

                if let onContinue {
                    OnboardingPrimaryButton(
                        title: "See your plan",
                        colorHex: colorHex,
                        action: onContinue
                    )
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
    }

    private var taskCard: some View {
        HStack(spacing: 12) {
            TaskIconView(iconName: taskIcon, colorHex: colorHex, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(previewRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(taskTitle.isEmpty ? "Your task" : taskTitle)
                    .font(.subheadline.weight(.semibold))
            }
            Spacer()
            CompletionCircleView(isCompleted: false, colorHex: colorHex, size: 24)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.white).shadow(color: .black.opacity(0.04), radius: 6, y: 2))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: colorHex).opacity(0.25), lineWidth: 1.5))
    }

    private var decorativeBg: some View {
        ZStack {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(hex: colors[i % colors.count]).opacity(0.08))
                    .frame(width: CGFloat([80,110,70,120,90][i]), height: CGFloat([80,110,70,120,90][i]))
                    .rotationEffect(.degrees(Double([-20,15,-30,25,-10][i])))
                    .offset(x: CGFloat([-130,140,-90,150,-50][i]), y: CGFloat([200,-40,380,430,100][i]))
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingTaskStylePage(
        taskTitle: .constant("Answer Emails"),
        taskIcon: .constant("envelope.fill"),
        duration: .constant(30),
        colorHex: .constant("#8FB872")
    )
}
