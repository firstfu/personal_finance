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
