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
                Spacer().frame(height: scaled(80))

                // Title
                VStack(alignment: .leading, spacing: scaled(6)) {
                    Text("Welcome to")
                        .font(.system(size: scaled(38), weight: .light))
                        .foregroundStyle(.white.opacity(0.88))
                    Text("Tickd")
                        .font(.system(size: scaled(44), weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, scaled(28))
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : scaled(14))

                Spacer()

                // Arrow button
                HStack {
                    Spacer()
                    if let onNext {
                        Button(action: onNext) {
                            Image(systemName: "arrow.right")
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: scaled(60), height: scaled(60))
                                .background(Circle().fill(.white.opacity(0.25)))
                                .overlay(Circle().strokeBorder(.white.opacity(0.4), lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, scaled(24))
                .padding(.bottom, scaled(40))
                .opacity(appeared ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.9).delay(0.15)) { appeared = true }
            Analytics.track(Analytics.Event.onboardingStarted)
        }
    }
}

#Preview {
    OnboardingWelcomePage(onNext: {})
}
