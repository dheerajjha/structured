import SwiftUI

/// Page 2: "Structured helps you..." with benefit cards
struct OnboardingBenefitsPage: View {
    private let coralColor = Color(hex: "#E8907E")

    private let benefits: [(icon: String, color: String, text: String)] = [
        ("eye.fill", "#B8C9E0", "stay focused and distraction-free"),
        ("text.line.first.and.arrowtriangle.forward", "#B8E0B8", "keep control on busy days"),
        ("trophy.fill", "#E0B8C9", "achieve your goals in the long haul"),
    ]

    var body: some View {
        ZStack {
            coralColor.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Structured")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)

                    Text("helps you...")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Benefit items
                VStack(spacing: 32) {
                    ForEach(benefits, id: \.text) { benefit in
                        benefitRow(
                            icon: benefit.icon,
                            bgColor: benefit.color,
                            text: benefit.text
                        )
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
                Spacer()
            }
        }
    }

    private func benefitRow(icon: String, bgColor: String, text: String) -> some View {
        HStack(spacing: 20) {
            // Sticky note style icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(hex: bgColor))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-5))
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.primary.opacity(0.6))
            }

            Text(text)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
}

#Preview {
    OnboardingBenefitsPage()
}
