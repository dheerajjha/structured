import SwiftUI

/// Page 1: "Welcome to Structured" with decorative elements
struct OnboardingWelcomePage: View {
    private let coralColor = Color(hex: "#E8907E")

    var body: some View {
        ZStack {
            // Coral background
            coralColor.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Title
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome to")
                        .font(.system(size: 38, weight: .light))
                        .foregroundStyle(.white.opacity(0.85))

                    Text("Structured")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                Spacer()

                // Decorative illustration area
                ZStack {
                    // Notebook illustration (using SF Symbols + shapes)
                    notebookIllustration
                        .offset(x: -40, y: -20)

                    // Coffee cup
                    coffeeIllustration
                        .offset(x: 120, y: -180)

                    // Pencil
                    pencilIllustration
                        .offset(x: 100, y: 60)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 400)

                Spacer()
            }
        }
    }

    // MARK: - Decorative Elements

    private var notebookIllustration: some View {
        ZStack {
            // Notebook shape
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.95))
                .frame(width: 220, height: 260)
                .rotationEffect(.degrees(-12))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)

            // Grid lines on notebook
            VStack(spacing: 16) {
                ForEach(0..<8, id: \.self) { _ in
                    Rectangle()
                        .fill(Color(hex: "#E8907E").opacity(0.1))
                        .frame(height: 0.5)
                }
            }
            .frame(width: 180, height: 220)
            .rotationEffect(.degrees(-12))

            // Handwritten text
            VStack(alignment: .leading, spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption)
                    .foregroundStyle(coralColor.opacity(0.5))

                Text("Let's plan")
                    .font(.system(size: 24, design: .serif))
                    .italic()
                    .foregroundStyle(coralColor.opacity(0.7))

                Text("your day")
                    .font(.system(size: 24, design: .serif))
                    .italic()
                    .foregroundStyle(coralColor.opacity(0.7))
            }
            .rotationEffect(.degrees(-12))
            .offset(x: -10, y: 10)
        }
    }

    private var coffeeIllustration: some View {
        ZStack {
            // Cup
            Circle()
                .fill(.white)
                .frame(width: 90, height: 90)
                .shadow(color: .black.opacity(0.1), radius: 5, y: 3)

            // Coffee color
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(hex: "#8B6914"), Color(hex: "#C49A3C")],
                        center: .center,
                        startRadius: 5,
                        endRadius: 35
                    )
                )
                .frame(width: 70, height: 70)

            // Latte art (heart shape)
            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var pencilIllustration: some View {
        ZStack {
            // Pencil body
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#F5D547"), Color(hex: "#E8C832")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 12, height: 100)

            // Pencil tip
            Triangle()
                .fill(Color(hex: "#D4A574"))
                .frame(width: 12, height: 20)
                .offset(y: 55)

            // Eraser
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#E8907E").opacity(0.6))
                .frame(width: 12, height: 15)
                .offset(y: -52)
        }
        .rotationEffect(.degrees(35))
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    OnboardingWelcomePage()
}
