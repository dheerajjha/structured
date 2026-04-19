import SwiftUI

/// Mirrors `TaskTextLimit` from the iOS target so Watch-originated edits stay
/// safely within WatchConnectivity payload limits when pushed to the phone.
enum WatchTaskTextLimit {
    static let title: Int   = 140
    static let notes: Int   = 2000
    static let subtask: Int = 140
    static let aiInput: Int = 500
}

extension String {
    func limited(to max: Int) -> String {
        guard count > max else { return self }
        return String(prefix(max))
    }
}

extension View {
    func characterLimit(_ text: Binding<String>, max: Int) -> some View {
        onChange(of: text.wrappedValue) { _, newValue in
            if newValue.count > max {
                text.wrappedValue = String(newValue.prefix(max))
            }
        }
    }
}
