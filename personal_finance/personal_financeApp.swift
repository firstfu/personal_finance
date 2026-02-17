import SwiftUI
import SwiftData
import WidgetKit

@main
struct personal_financeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
        ])

        let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.firstfu.personal-finance")!
            .appending(path: "default.store")

        // Migrate existing data from old location if needed
        let oldURL = URL.applicationSupportDirectory
            .appending(path: "default.store")
        if FileManager.default.fileExists(atPath: oldURL.path())
            && !FileManager.default.fileExists(atPath: appGroupURL.path()) {
            try? FileManager.default.copyItem(at: oldURL, to: appGroupURL)
            // Also copy WAL and SHM files if they exist
            let walURL = oldURL.deletingPathExtension().appendingPathExtension("store-wal")
            let shmURL = oldURL.deletingPathExtension().appendingPathExtension("store-shm")
            let newWal = appGroupURL.deletingPathExtension().appendingPathExtension("store-wal")
            let newShm = appGroupURL.deletingPathExtension().appendingPathExtension("store-shm")
            if FileManager.default.fileExists(atPath: walURL.path()) {
                try? FileManager.default.copyItem(at: walURL, to: newWal)
            }
            if FileManager.default.fileExists(atPath: shmURL.path()) {
                try? FileManager.default.copyItem(at: shmURL, to: newShm)
            }
        }

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: appGroupURL,
            allowsSave: true
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
                    let context = sharedModelContainer.mainContext
                    DefaultCategories.seed(into: context)
                    DefaultCategories.seedAccounts(into: context)
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
