import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("General") {
                    Label("Notifications", systemImage: "bell")
                    Label("Appearance", systemImage: "paintbrush")
                }
                Section("About") {
                    Label("Version 1.0", systemImage: "info.circle")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
