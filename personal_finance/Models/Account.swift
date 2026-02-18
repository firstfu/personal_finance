// ============================================================================
// MARK: - Account.swift
// 模組：Models
//
// 功能說明：
//   定義帳戶資料模型，用於記錄使用者的各種金融帳戶（現金、銀行、信用卡等）。
//   每筆交易可關聯至一個帳戶，帳戶可自動計算目前餘額。
//
// 主要職責：
//   - 以 SwiftData @Model 定義帳戶的持久化結構
//   - 管理帳戶名稱、類型、圖示、顏色與初始餘額
//   - 透過 initialBalanceString 以字串儲存初始餘額，確保 Decimal 精度
//   - 透過反向關聯（inverse）維護與 Transaction 的多對一關係
//   - 提供 currentBalance 計算屬性，自動彙算帳戶目前餘額
//
// 關鍵屬性：
//   - name: 帳戶名稱（如「現金」、「銀行存款」、「信用卡」）
//   - type: 帳戶類型，型別為 AccountType 列舉
//   - icon: SF Symbols 圖示名稱
//   - colorHex: 帳戶代表色的十六進位色碼
//   - initialBalanceString: 初始餘額的字串表示，實際儲存於 SwiftData
//   - initialBalance: @Transient 計算屬性，提供 Decimal 型別的初始餘額讀寫介面
//   - sortOrder: 排序順序
//   - isDefault: 是否為系統預設帳戶，預設帳戶在 UI 中禁止刪除
//   - seedIdentifier: 種子資料識別碼，用於 seed 時避免重複植入
//   - transactions: 反向關聯的交易陣列（deleteRule 為 nullify）
//   - currentBalance: 計算屬性，以初始餘額加上收入減去支出得出目前餘額
//
// 注意事項：
//   - isDefault == true 的帳戶在 UI 層禁止刪除，但 Model 層無強制保護機制
//   - 刪除帳戶時，關聯的交易 account 欄位將被設為 nil（nullify）
//   - currentBalance 每次存取皆重新計算，若交易量大可能影響效能
// ============================================================================

import Foundation
import SwiftData

@Model
final class Account {
    var name: String = ""
    var type: AccountType = AccountType.cash
    var icon: String = ""
    var colorHex: String = "#000000"
    var initialBalanceString: String = "0"
    var sortOrder: Int = 0
    var isDefault: Bool = false
    var seedIdentifier: String = ""

    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    var transactions: [Transaction]? = []

    @Relationship(deleteRule: .nullify, inverse: \Transaction.transferToAccount)
    var transferInTransactions: [Transaction]? = []

    @Transient
    var initialBalance: Decimal {
        get { Decimal(string: initialBalanceString) ?? 0 }
        set { initialBalanceString = "\(newValue)" }
    }

    init(name: String, type: AccountType, icon: String, colorHex: String, initialBalance: Decimal = 0, sortOrder: Int = 0, isDefault: Bool = false, seedIdentifier: String = "") {
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.initialBalanceString = "\(initialBalance)"
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.seedIdentifier = seedIdentifier
        self.transactions = []
    }

    var demoBalance: Decimal {
        let demoTransactions = (transactions ?? []).filter { $0.isDemoData }
        let incomeTotal = demoTransactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expenseTotal = demoTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let transferOutTotal = demoTransactions
            .filter { $0.type == .transfer }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let demoTransferIn = (transferInTransactions ?? []).filter { $0.isDemoData }
        let transferInTotal = demoTransferIn
            .reduce(Decimal.zero) { $0 + $1.amount }
        let adjustmentTotal = demoTransactions
            .filter { $0.type == .adjustment }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return incomeTotal - expenseTotal - transferOutTotal + transferInTotal + adjustmentTotal
    }

    var currentBalance: Decimal {
        let allTransactions = (transactions ?? []).filter { !$0.isDemoData }
        let incomeTotal = allTransactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expenseTotal = allTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let transferOutTotal = allTransactions
            .filter { $0.type == .transfer }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let transferInTotal = (transferInTransactions ?? []).filter { !$0.isDemoData }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let adjustmentTotal = allTransactions
            .filter { $0.type == .adjustment }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return initialBalance + incomeTotal - expenseTotal - transferOutTotal + transferInTotal + adjustmentTotal
    }
}
