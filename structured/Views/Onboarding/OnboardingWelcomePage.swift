import SwiftUI

/// Page 1: Welcome — full-screen coral, watercolor at low alpha, arrow button embedded
struct OnboardingWelcomePage: View {
    var onNext: (@MainActor () -> Void)? = nil
    @State private var appeared = false

    private let coral = Color(hex: "#D4806E")

    var body: some View {
        ZStack {
            coral.ignoresSafeArea()

            Image("OnboardingWelcome")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .opacity(appeared ? 0.18 : 0)
                .scaleEffect(appeared ? 1.0 : 1.06)

            VStack(alignment: .leading) {
                // Top padding to clear the topBar overlay
                Spacer().frame(height: 80)

                // Title
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome to")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(.white.opacity(0.88))
                    Text("Structured")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 28)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 14)

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
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) { appeared = true }
        }
    }
}

#Preview {
    OnboardingWelcomePage(onNext: {})
}
