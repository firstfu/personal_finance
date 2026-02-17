// ============================================================================
// MARK: - personal_financeApp.swift
// 模組：App 進入點
//
// 功能說明：
//   這個檔案定義了應用程式的主要進入點（@main），負責初始化 SwiftData
//   ModelContainer、植入預設資料，以及設定 CloudKit 遠端變更監聽。
//
// 主要職責：
//   - 建立並配置 SwiftData ModelContainer（含 CloudKit 私有資料庫）
//   - 註冊所有 SwiftData Schema（Transaction、Category、Account）
//   - 設定資料遷移計畫（FinanceMigrationPlan）
//   - App 啟動時執行舊版 App Group 資料遷移（MigrationService）
//   - 植入預設分類與帳戶（DefaultCategories.seed）
//   - 同步 Widget 快照資料（WidgetDataSync）
//   - 監聽 CloudKit 遠端變更通知以即時更新 Widget
//
// 注意事項：
//   - ModelContainer 建立失敗會觸發 fatalError
//   - 根視圖為 ContentView，透過 .modelContainer 注入資料容器
// ============================================================================

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
            SproutPlant.self,
            HarvestRecord.self,
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

                    // Clean up any duplicate seed data
                    DefaultCategories.removeDuplicates(from: context)

                    // Seed defaults (dedup by seedIdentifier)
                    DefaultCategories.seed(into: context)
                    DefaultCategories.seedAccounts(into: context)

                    // Seed initial sprout plant if none exists
                    let sproutService = SproutGrowthService(modelContext: context)
                    _ = sproutService.getActivePlant()

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
