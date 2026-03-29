import SwiftUI

/// Page 3: "Let's get started by planning today/tomorrow..."
struct OnboardingGetStartedPage: View {
    @Binding var planForToday: Bool

    private let coralColor = Color(hex: "#E8907E")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                (Text("Let's get started by planning ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                 +
                 Text(planForToday ? "today" : "tomorrow")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(coralColor)
                 +
                 Text("...")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                )

                Text("This will only take a few steps")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            // Decorative illustration
            ZStack {
                // Color circles at top
                HStack(spacing: 16) {
                    ForEach(0..<7, id: \.self) { index in
                        Circle()
                            .fill(coralColor.opacity(0.15 + Double(index) * 0.05))
                            .frame(width: 40, height: 40)
                    }
                }
                .offset(y: -120)

                // Task block illustration
                VStack(spacing: 0) {
                    // Task icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: "#7C97AB"))
                            .frame(width: 60, height: 70)

                        Image(systemName: "cart.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                    .offset(x: -80, y: -60)

                    // Title bars
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray3))
                            .frame(width: 100, height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(.systemGray4))
                            .frame(width: 40, height: 8)
                    }
                    .offset(y: -70)

                    // Checkmark
                    Image(systemName: "checkmark.circle")
                        .font(.title)
                        .foregroundStyle(Color(hex: "#7C97AB").opacity(0.5))
                        .offset(x: 80, y: -90)

                    // Dashed circle
                    Circle()
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [4]))
                        .foregroundStyle(coralColor.opacity(0.3))
                        .frame(width: 50, height: 50)
                        .offset(x: -80, y: -40)

                    // Person illustration using shapes
                    personIllustration
                        .offset(y: -10)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 380)

            Spacer()
        }
    }

    private var personIllustration: some View {
        ZStack {
            // Body
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F5E0D8"), Color(hex: "#EDD0C5")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 160, height: 180)
                .offset(y: 40)

            // Head
            Circle()
                .fill(Color(hex: "#F5DDD0"))
                .frame(width: 60, height: 60)
                .offset(y: -50)

            // Hair
            Circle()
                .fill(Color(hex: "#C47A5A"))
                .frame(width: 65, height: 40)
                .offset(y: -65)

            // Left arm holding task
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: "#7C97AB"))
                    .frame(width: 40, height: 50)

                Image(systemName: "graduationcap.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
            }
            .offset(x: -70, y: -10)

            // Right arm with pen
            Circle()
                .fill(Color(hex: "#7C97AB"))
                .frame(width: 24, height: 24)
                .offset(x: 70, y: -30)
        }
    }
}

#Preview {
    OnboardingGetStartedPage(planForToday: .constant(true))
}
