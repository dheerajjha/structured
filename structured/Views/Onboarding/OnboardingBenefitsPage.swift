import SwiftUI

/// Page 2: Benefits — coral bg, watercolor at low alpha, arrow button embedded
struct OnboardingBenefitsPage: View {
    var onNext: (@MainActor () -> Void)? = nil
    @State private var appeared = false

    private let coral = Color(hex: "#D4806E")

    private let benefits: [(icon: String, color: String, text: String, detail: String)] = [
        ("eye.fill",          "#B8D4E8", "stay focused",       "cut through distractions with a clear plan"),
        ("square.stack.fill", "#B8E0C4", "keep control",       "on your busiest days"),
        ("trophy.fill",       "#E8D4B8", "achieve your goals", "in the long haul"),
    ]

    var body: some View {
        ZStack {
            coral.ignoresSafeArea()

            Image("OnboardingBenefits")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .opacity(appeared ? 0.14 : 0)
                .scaleEffect(appeared ? 1.0 : 1.04)

            VStack(alignment: .leading) {
                Spacer().frame(height: 80)

                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Structured")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                    Text("helps you...")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                Spacer()

                // Benefit rows
                VStack(spacing: 26) {
                    ForEach(Array(benefits.enumerated()), id: \.element.text) { i, b in
                        benefitRow(b, delay: Double(i) * 0.1)
                    }
                }
                .padding(.horizontal, 28)

                Spacer()

                // Arrow button
                HStack {
                    Spacer()
                    if let onNext {
                        Button(action: onNext) {
                            Image(systemName: "arrow.right")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(.white.opacity(0.25)))
                                .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) { appeared = true }
        }
    }

    private func benefitRow(_ b: (icon: String, color: String, text: String, detail: String), delay: Double) -> some View {
        HStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: b.color).opacity(0.88))
                    .frame(width: 62, height: 62)
                    .rotationEffect(.degrees(-4))
                    .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                Image(systemName: b.icon)
                    .font(.title2)
                    .foregroundStyle(Color(hex: "#3D3D3D").opacity(0.55))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(b.text)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(b.detail)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.72))
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -16)
        .animation(.easeOut(duration: 0.5).delay(0.3 + delay), value: appeared)
    }
}

#Preview {
    OnboardingBenefitsPage(onNext: {})
}
