import SwiftUI

/// Circular colored icon used on task blocks — matches Tickd's design
struct TaskIconView: View {
    let iconName: String
    let colorHex: String
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(Color(hex: colorHex))
                .frame(width: size, height: size)

            Image(systemName: iconName)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
    }
}

/// Completion toggle circle on the right side of task blocks
struct CompletionCircleView: View {
    let isCompleted: Bool
    let colorHex: String
    var size: CGFloat = 26

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: colorHex), lineWidth: 2)
                .frame(width: size, height: size)

            if isCompleted {
                Circle()
                    .fill(Color(hex: colorHex))
                    .frame(width: size, height: size)

                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        TaskIconView(iconName: "book.fill", colorHex: "#FF6B6B")
        TaskIconView(iconName: "figure.run", colorHex: "#34C759")
        TaskIconView(iconName: "briefcase.fill", colorHex: "#007AFF")
        CompletionCircleView(isCompleted: false, colorHex: "#FF6B6B")
        CompletionCircleView(isCompleted: true, colorHex: "#34C759")
    }
    .padding()
}
