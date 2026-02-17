// ============================================================================
// MARK: - Transaction.swift
// 模組：Models
//
// 功能說明：
//   定義交易（記帳）資料模型，為整個應用程式的核心資料實體。
//   每一筆交易記錄包含金額、類型（收入/支出）、分類、帳戶、備註與日期。
//
// 主要職責：
//   - 以 SwiftData @Model 定義交易的持久化結構
//   - 透過 amountString 以字串形式儲存金額，確保 Decimal 精度不流失
//   - 提供 @Transient computed property 將字串金額轉換為 Decimal 使用
//   - 關聯 Category（分類）與 Account（帳戶），皆為可選的多對一關係
//
// 關鍵屬性：
//   - amountString: 金額的字串表示，實際儲存於 SwiftData（避免 Decimal 序列化問題）
//   - amount: @Transient 計算屬性，提供 Decimal 型別的金額讀寫介面
//   - type: 交易類型（收入 / 支出），型別為 TransactionType 列舉
//   - category: 關聯的分類（可為 nil），刪除規則為 nullify
//   - account: 關聯的帳戶（可為 nil），刪除規則為 nullify
//   - note: 使用者輸入的備註文字
//   - date: 交易發生日期（使用者可選擇）
//   - createdAt: 記錄建立時間（系統自動產生）
//   - isDemoData: 標記是否為範例資料，供一鍵清除使用
//   - seedIdentifier: 種子資料識別碼，用於避免重複植入
//
// 注意事項：
//   - 目前交易僅支援新增，不支援編輯或單筆刪除（僅有全部重置功能）
//   - 金額使用 Decimal 型別確保精度，僅在 Charts 渲染時轉為 Double
// ============================================================================

import Foundation
import SwiftData

@Model
final class Transaction {
    var amountString: String = "0"
    var type: TransactionType = TransactionType.expense
    var category: Category?
    var account: Account?
    var transferToAccount: Account?
    var note: String = ""
    var date: Date = Date.now
    var createdAt: Date = Date.now
    var isDemoData: Bool = false
    var seedIdentifier: String = ""

    @Transient
    var amount: Decimal {
        get { Decimal(string: amountString) ?? 0 }
        set { amountString = "\(newValue)" }
    }

    init(amount: Decimal, type: TransactionType, category: Category? = nil, account: Account? = nil, transferToAccount: Account? = nil, note: String = "", date: Date = .now, isDemoData: Bool = false) {
        self.amountString = "\(amount)"
        self.type = type
        self.category = category
        self.account = account
        self.transferToAccount = transferToAccount
        self.note = note
        self.date = date
        self.createdAt = .now
        self.isDemoData = isDemoData
    }
}
