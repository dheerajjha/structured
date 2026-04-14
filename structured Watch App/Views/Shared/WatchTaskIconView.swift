import SwiftUI

struct WatchTaskIconView: View {
    let iconName: String
    let colorHex: String
    var size: CGFloat = 28

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

struct WatchCompletionCircle: View {
    let isCompleted: Bool
    let colorHex: String
    var size: CGFloat = 20

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
