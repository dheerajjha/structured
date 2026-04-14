import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var timelineViewModel = WatchTimelineViewModel()
    @State private var aiViewModel = WatchAIViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchTimelineView(viewModel: timelineViewModel)
                .tag(0)
                .tabItem {
                    Label("Today", systemImage: "list.bullet.below.rectangle")
                }

            WatchInboxView()
                .tag(1)
                .tabItem {
                    Label("Later", systemImage: "tray.fill")
                }

            WatchAIView(viewModel: aiViewModel)
                .tag(2)
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }

            WatchSettingsView()
                .tag(3)
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

#Preview {
    ContentView()
}
