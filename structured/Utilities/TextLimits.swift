import SwiftUI

/// Shared maximum lengths for user-generated text so we never overflow
/// WatchConnectivity payloads (~64KB) or create unreadable UI.
enum TaskTextLimit {
    static let title: Int    = 140
    static let notes: Int    = 2000
    static let subtask: Int  = 140
    static let aiInput: Int  = 1000
}

extension String {
    /// Clamp a string to `max` characters. Safe with multi-scalar graphemes.
    func limited(to max: Int) -> String {
        guard count > max else { return self }
        return String(prefix(max))
    }
}

extension View {
    /// Keep a bound `String` at or below `max` characters. Trims on assign.
    func characterLimit(_ text: Binding<String>, max: Int) -> some View {
        onChange(of: text.wrappedValue) { _, newValue in
            if newValue.count > max {
                text.wrappedValue = String(newValue.prefix(max))
            }
        }
    }
}
