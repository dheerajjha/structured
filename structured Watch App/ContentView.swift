import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Int = 0
    @State private var timelineViewModel = WatchTimelineViewModel()
    @State private var aiViewModel = WatchAIViewModel()

    var body: some View {
        TabView(selection: $selectedTab) {
            WatchTimelineView(viewModel: timelineViewModel)
                .tag(0)

            WatchInboxView()
                .tag(1)

            WatchAIView(viewModel: aiViewModel)
                .tag(2)

            WatchSettingsView()
                .tag(3)
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    ContentView()
}
