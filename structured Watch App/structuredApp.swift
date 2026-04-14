import SwiftUI
import SwiftData

@main
struct structured_Watch_AppApp: App {
    let sharedModelContainer: ModelContainer

    init() {
        let schema = Schema([
            WatchTask.self,
            WatchSubtask.self,
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            self.sharedModelContainer = container
            WatchConnectivityManager.shared.modelContainer = container
            WatchConnectivityManager.shared.activate()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
