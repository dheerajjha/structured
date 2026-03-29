import SwiftUI

// MARK: - Preset Task Colors

struct TaskColor: Identifiable, Hashable {
    let id: String
    let name: String
    let hex: String

    var color: Color { Color(hex: hex) }
}

enum TaskColors {
    static let all: [TaskColor] = [
        TaskColor(id: "coral", name: "Coral", hex: "#FF6B6B"),
        TaskColor(id: "orange", name: "Orange", hex: "#FF9500"),
        TaskColor(id: "yellow", name: "Yellow", hex: "#FFCC00"),
        TaskColor(id: "green", name: "Green", hex: "#34C759"),
        TaskColor(id: "mint", name: "Mint", hex: "#00C7BE"),
        TaskColor(id: "teal", name: "Teal", hex: "#5AC8FA"),
        TaskColor(id: "blue", name: "Blue", hex: "#007AFF"),
        TaskColor(id: "indigo", name: "Indigo", hex: "#5856D6"),
        TaskColor(id: "purple", name: "Purple", hex: "#AF52DE"),
        TaskColor(id: "pink", name: "Pink", hex: "#FF2D55"),
        TaskColor(id: "brown", name: "Brown", hex: "#A2845E"),
        TaskColor(id: "gray", name: "Gray", hex: "#8E8E93"),
    ]

    static let `default` = all[0]

    static func color(for hex: String) -> TaskColor {
        all.first { $0.hex == hex } ?? `default`
    }
}

// MARK: - Color from Hex

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 255, 107, 107)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Returns a lighter version for task block backgrounds
    func pastel(opacity: Double = 0.15) -> Color {
        self.opacity(opacity)
    }
}
