// ============================================================================
// MARK: - BackupModels.swift
// 模組：Services
//
// 功能說明：
//   這個檔案定義了備份/還原功能所需的所有資料傳輸物件（DTO）與文件結構。
//   這些 Codable 結構體作為 SwiftData Model 與 JSON 備份檔案之間的橋樑，
//   確保序列化/反序列化過程中的資料完整性。
//
// 主要職責：
//   - 定義備份文件的頂層結構（BackupDocument）
//   - 定義備份摘要資訊（BackupSummary）
//   - 定義分類、帳戶、交易的 DTO 結構，用於 JSON 序列化
//
// 關鍵類型：
//   - BackupDocument: 備份文件根結構，包含版本號、建立時間、App 版本、
//     摘要及所有資料集合
//   - BackupSummary: 備份摘要，記錄交易/分類/帳戶的總數量
//   - CategoryDTO: 分類的資料傳輸物件，含 backupId 用於關聯對映
//   - AccountDTO: 帳戶的資料傳輸物件，金額以 String 儲存保留 Decimal 精度
//   - TransactionDTO: 交易的資料傳輸物件，透過 categoryBackupId 與
//     accountBackupId 維持關聯關係
//
// 注意事項：
//   - 所有金額欄位（initialBalance、amount）使用 String 型別，
//     避免 JSON 編碼時 Decimal 精度流失
//   - backupId 為備份時產生的 UUID，與 SwiftData 的 PersistentIdentifier 無關
//   - 日期欄位在編碼時使用 ISO 8601 格式
// ============================================================================

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
    let seedIdentifier: String?
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
    let seedIdentifier: String?
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
