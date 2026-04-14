import SwiftUI
import SwiftData
import BugReporterSDK

@main
struct structuredApp: App {
    init() {
        BugReporter.start(config: BugReporterConfig(
            apiURL: URL(string: "https://bug.heywrist.com")!,
            apiKey: "structured-ios-dev",
            userEmail: "tester@heywrist.com",
            mode: .debug,
            enableScreenshotDetection: true,
            enableFloatingButton: false,
            maxNetworkLogEntries: 50
        ))
        Analytics.setup()
        Analytics.track(Analytics.Event.appOpened)
    }

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StructuredTask.self,
            Subtask.self,
        ])
        // TODO: Add App Group + CloudKit once entitlements are configured:
        // groupContainer: .identifier("group.heywrist.structured"),
        // cloudKitDatabase: .automatic
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    WatchSyncManager.shared.modelContainer = sharedModelContainer
                    WatchSyncManager.shared.activate()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
