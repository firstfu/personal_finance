// ============================================================================
// MARK: - MigrationService.swift
// 模組：Services
//
// 功能說明：
//   這個檔案定義了資料遷移服務，負責將舊版 App Group SQLite 資料庫或
//   舊版 Application Support 目錄中的 SwiftData 資料，遷移至新的
//   CloudKit 管理的資料儲存區。遷移過程透過 BackupService 進行序列化
//   與反序列化，確保資料完整性。
//
// 主要職責：
//   - 偵測是否需要進行 CloudKit 遷移（透過 UserDefaults 旗標）
//   - 自動尋找舊版資料來源（App Group 或 Application Support）
//   - 將舊資料匯出為備份格式，再匯入新的 ModelContext
//   - 遷移完成後將舊資料庫重新命名為安全備份
//
// 關鍵屬性/方法：
//   - migrationKey: UserDefaults 鍵值，記錄遷移是否已完成
//   - needsMigration: Bool，判斷是否仍需執行遷移
//   - migrateIfNeeded(to:): 主要遷移方法，讀取舊資料庫、匯出備份、
//     匯入新 context，並將舊 .store / .store-wal / .store-shm 重新命名
//
// 注意事項：
//   - 遷移失敗時不會標記為完成，下次啟動時會自動重試
//   - 舊資料庫以唯讀模式開啟（allowsSave: false）
//   - 同時處理 WAL 與 SHM 附屬檔案的搬移
// ============================================================================

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
