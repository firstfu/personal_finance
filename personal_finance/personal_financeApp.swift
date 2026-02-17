import SwiftUI
import SwiftData
import CoreData
import WidgetKit

@main
struct personal_financeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
        ])

        let cloudConfig = ModelConfiguration(
            schema: schema,
            cloudKitDatabase: .private("iCloud.com.firstfu.com.personal-finance")
        )

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: FinanceMigrationPlan.self,
                configurations: [cloudConfig]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    let context = sharedModelContainer.mainContext

                    // One-time migration from old App Group store
                    MigrationService.migrateIfNeeded(to: context)

                    // Seed defaults (dedup by seedIdentifier)
                    DefaultCategories.seed(into: context)
                    DefaultCategories.seedAccounts(into: context)

                    // Update widget snapshot
                    WidgetDataSync.updateSnapshot(from: context)

                    // Listen for CloudKit remote changes
                    NotificationCenter.default.addObserver(
                        forName: .NSPersistentStoreRemoteChange,
                        object: nil,
                        queue: .main
                    ) { _ in
                        WidgetDataSync.updateSnapshot(from: context)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
