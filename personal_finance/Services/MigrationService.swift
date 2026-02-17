import Foundation
import SwiftData

enum MigrationService {
    private static let migrationKey = "hasCompletedCloudKitMigration"

    static var needsMigration: Bool {
        !UserDefaults.standard.bool(forKey: migrationKey)
    }

    /// Migrate data from old App Group SQLite store to the new CloudKit-managed store.
    /// Uses BackupService to serialize/deserialize data.
    static func migrateIfNeeded(to newContext: ModelContext) {
        guard needsMigration else { return }

        let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.firstfu.personal-finance")?
            .appending(path: "default.store")

        // Also check old Application Support location
        let oldAppSupportURL = URL.applicationSupportDirectory
            .appending(path: "default.store")

        // Determine which old store to migrate from
        let sourceURL: URL? = {
            if let groupURL = appGroupURL,
               FileManager.default.fileExists(atPath: groupURL.path()) {
                return groupURL
            } else if FileManager.default.fileExists(atPath: oldAppSupportURL.path()) {
                return oldAppSupportURL
            }
            return nil
        }()

        guard let sourceURL else {
            // No old data to migrate — mark as done
            UserDefaults.standard.set(true, forKey: migrationKey)
            return
        }

        do {
            // Open old store read-only
            let oldSchema = Schema([Transaction.self, Category.self, Account.self])
            let oldConfig = ModelConfiguration(
                schema: oldSchema,
                url: sourceURL,
                allowsSave: false
            )
            let oldContainer = try ModelContainer(for: oldSchema, configurations: [oldConfig])
            let oldContext = ModelContext(oldContainer)
            oldContext.autosaveEnabled = false

            // Export data using BackupService
            let backup = try BackupService.createBackup(context: oldContext)

            // Only restore if there's actual data
            if backup.summary.totalTransactions > 0 || backup.summary.totalCategories > 0 {
                try BackupService.restore(backup, into: newContext)
            }

            // Rename old store as safety backup
            let backupURL = sourceURL.deletingLastPathComponent()
                .appending(path: "default.store.pre-cloudkit-backup")
            if !FileManager.default.fileExists(atPath: backupURL.path()) {
                try? FileManager.default.moveItem(at: sourceURL, to: backupURL)
                // Move WAL and SHM too
                let walURL = sourceURL.deletingPathExtension().appendingPathExtension("store-wal")
                let shmURL = sourceURL.deletingPathExtension().appendingPathExtension("store-shm")
                if FileManager.default.fileExists(atPath: walURL.path()) {
                    try? FileManager.default.moveItem(
                        at: walURL,
                        to: backupURL.deletingPathExtension().appendingPathExtension("store-wal.pre-cloudkit-backup")
                    )
                }
                if FileManager.default.fileExists(atPath: shmURL.path()) {
                    try? FileManager.default.moveItem(
                        at: shmURL,
                        to: backupURL.deletingPathExtension().appendingPathExtension("store-shm.pre-cloudkit-backup")
                    )
                }
            }

            UserDefaults.standard.set(true, forKey: migrationKey)
        } catch {
            // Migration failed — don't mark as complete so it retries next launch
            print("CloudKit migration failed: \(error)")
        }
    }
}
