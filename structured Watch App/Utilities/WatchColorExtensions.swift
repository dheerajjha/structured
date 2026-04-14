import SwiftUI

// MARK: - Preset Task Colors

struct WatchTaskColor: Identifiable, Hashable {
    let id: String
    let name: String
    let hex: String

    var color: Color { Color(hex: hex) }
}

enum WatchTaskColors {
    static let all: [WatchTaskColor] = [
        WatchTaskColor(id: "coral", name: "Coral", hex: "#FF6B6B"),
        WatchTaskColor(id: "orange", name: "Orange", hex: "#FF9500"),
        WatchTaskColor(id: "yellow", name: "Yellow", hex: "#FFCC00"),
        WatchTaskColor(id: "green", name: "Green", hex: "#34C759"),
        WatchTaskColor(id: "mint", name: "Mint", hex: "#00C7BE"),
        WatchTaskColor(id: "teal", name: "Teal", hex: "#5AC8FA"),
        WatchTaskColor(id: "blue", name: "Blue", hex: "#007AFF"),
        WatchTaskColor(id: "indigo", name: "Indigo", hex: "#5856D6"),
        WatchTaskColor(id: "purple", name: "Purple", hex: "#AF52DE"),
        WatchTaskColor(id: "pink", name: "Pink", hex: "#FF2D55"),
        WatchTaskColor(id: "brown", name: "Brown", hex: "#A2845E"),
        WatchTaskColor(id: "gray", name: "Gray", hex: "#8E8E93"),
    ]

    static let `default` = all[0]
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

    func pastel(opacity: Double = 0.15) -> Color {
        self.opacity(opacity)
    }
}
