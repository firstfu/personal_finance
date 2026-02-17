// ============================================================================
// MARK: - SchemaVersioning.swift
// 模組：Models
//
// 功能說明：
//   定義 SwiftData 的 Schema 版本控制與遷移計畫。
//   管理資料庫結構的版本演進，確保 App 升級時資料能正確遷移。
//
// 主要職責：
//   - 定義 SchemaV1（初始版本）與 SchemaV2（CloudKit 相容版本）
//   - 宣告每個版本包含的 Model 型別（Transaction、Category、Account）
//   - 定義 FinanceMigrationPlan 遷移計畫，管理版本升級路徑
//   - 提供 V1 到 V2 的輕量遷移（lightweight migration）
//
// 關鍵型別：
//   - SchemaV1: 初始版本 Schema（1.0.0），Pre-CloudKit 快照
//   - SchemaV2: CloudKit 相容版本 Schema（2.0.0）
//   - FinanceMigrationPlan: 遷移計畫，定義所有 Schema 與遷移階段
//
// 關鍵屬性/方法：
//   - SchemaV1.versionIdentifier: 版本號 1.0.0
//   - SchemaV2.versionIdentifier: 版本號 2.0.0
//   - FinanceMigrationPlan.schemas: 所有版本的 Schema 陣列
//   - FinanceMigrationPlan.stages: 遷移階段陣列
//   - migrateV1toV2: V1 到 V2 的輕量遷移定義
//
// 注意事項：
//   - V1 到 V2 使用 lightweight migration，SwiftData 自動處理新欄位的預設值
//   - 實際的資料從舊 App Group Store 遷移到新 CloudKit Store 由 MigrationService 處理
//   - 新增 Model 欄位時需確保提供預設值，以支援輕量遷移
// ============================================================================

import Foundation
import SwiftData

// MARK: - Schema V1 (Pre-CloudKit snapshot, for reference)

enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Transaction.self, Category.self, Account.self]
    }
}

// MARK: - Schema V2 (CloudKit Compatible)

enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Transaction.self, Category.self, Account.self]
    }
}

// MARK: - Migration Plan

enum FinanceMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // Lightweight migration: SwiftData auto-handles adding new columns with defaults.
    // Actual data migration from old App Group store to new CloudKit store
    // is handled by MigrationService at app startup.
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
