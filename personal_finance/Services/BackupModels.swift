import Foundation

struct BackupDocument: Codable {
    let version: Int
    let createdAt: Date
    let appVersion: String
    let summary: BackupSummary
    let categories: [CategoryDTO]
    let accounts: [AccountDTO]
    let transactions: [TransactionDTO]
}

struct BackupSummary: Codable {
    let totalTransactions: Int
    let totalCategories: Int
    let totalAccounts: Int
}

struct CategoryDTO: Codable {
    let backupId: UUID
    let name: String
    let icon: String
    let colorHex: String
    let type: String
    let sortOrder: Int
    let isDefault: Bool
}

struct AccountDTO: Codable {
    let backupId: UUID
    let name: String
    let type: String
    let icon: String
    let colorHex: String
    let initialBalance: String
    let sortOrder: Int
    let isDefault: Bool
}

struct TransactionDTO: Codable {
    let amount: String
    let type: String
    let categoryBackupId: UUID?
    let accountBackupId: UUID?
    let note: String
    let date: Date
    let createdAt: Date
}

struct BackupFileInfo: Identifiable {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: Int64
    let createdAt: Date
    let summary: BackupSummary?
}
