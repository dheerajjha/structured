import SwiftUI
import SwiftData

@main
struct structuredApp: App {
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
        }
        .modelContainer(sharedModelContainer)
    }
}
