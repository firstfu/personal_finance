//
//  Category.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - Category.swift
// 模組：Models
//
// 功能說明：
//   定義分類資料模型，用於將交易記錄歸類至不同的消費或收入類別。
//   預設提供 8 種支出分類與 4 種收入分類，使用者亦可自行新增。
//
// 主要職責：
//   - 以 SwiftData @Model 定義分類的持久化結構
//   - 管理分類的名稱、圖示、顏色與排序
//   - 透過反向關聯（inverse）維護與 Transaction 的多對一關係
//   - 區分系統預設分類與使用者自訂分類
//
// 關鍵屬性：
//   - name: 分類名稱（如「飲食」、「交通」、「薪資」等）
//   - icon: SF Symbols 圖示名稱（如 "fork.knife"、"car.fill"）
//   - colorHex: 分類代表色的十六進位色碼（如 "#FF9800"）
//   - type: 分類所屬的交易類型（收入或支出）
//   - sortOrder: 排序順序，數字越小越前面
//   - isDefault: 是否為系統預設分類，預設分類在 UI 中禁止刪除
//   - seedIdentifier: 種子資料識別碼，用於 seed 時避免重複植入
//   - transactions: 反向關聯的交易陣列（deleteRule 為 nullify）
//
// 注意事項：
//   - isDefault == true 的分類在 UI 層禁止刪除，但 Model 層無強制保護機制
//   - 刪除分類時，關聯的交易 category 欄位將被設為 nil（nullify）
// ============================================================================

import Foundation
import SwiftData

@Model
final class Category {
    var name: String = ""
    var icon: String = ""
    var colorHex: String = "#000000"
    var type: TransactionType = TransactionType.expense
    var sortOrder: Int = 0
    var isDefault: Bool = false
    var seedIdentifier: String = ""

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]? = []

    init(name: String, icon: String, colorHex: String, type: TransactionType, sortOrder: Int, isDefault: Bool = false, seedIdentifier: String = "") {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.seedIdentifier = seedIdentifier
        self.transactions = []
    }
}
