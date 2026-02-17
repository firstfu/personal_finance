//
//  DefaultCategories.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - DefaultCategories.swift
// 模組：Models
//
// 功能說明：
//   定義應用程式預設的分類與帳戶種子資料，並提供植入（seed）方法。
//   App 首次啟動時會呼叫此處的 seed 方法，將預設分類與帳戶寫入資料庫。
//
// 主要職責：
//   - 定義 CategoryData 與 AccountData 結構，描述種子資料的欄位
//   - 提供 8 種預設支出分類（飲食、交通、娛樂、購物、居住、醫療、教育、其他）
//   - 提供 4 種預設收入分類（薪資、獎金、投資、其他）
//   - 提供 3 個預設帳戶（現金、銀行存款、信用卡）
//   - 透過 seed(into:) 方法將分類植入 ModelContext（跳過已存在的項目）
//   - 透過 seedAccounts(into:) 方法將帳戶植入 ModelContext（跳過已存在的項目）
//
// 關鍵方法：
//   - seed(into:): 植入預設分類，以 seedIdentifier 判斷是否已存在
//   - seedAccounts(into:): 植入預設帳戶，以 seedIdentifier 判斷是否已存在
//
// 關鍵屬性：
//   - all: 所有預設分類（支出 + 收入）的陣列
//   - expense: 預設支出分類陣列（8 筆）
//   - income: 預設收入分類陣列（4 筆）
//   - defaultAccounts: 預設帳戶陣列（3 筆）
//
// 注意事項：
//   - 植入的分類與帳戶 isDefault 皆為 true，UI 層應禁止使用者刪除
//   - 以 seedIdentifier 作為冪等性檢查依據，確保重複執行不會產生重複資料
//   - 此 enum 同時管理分類與帳戶的種子資料，未來可考慮拆分
// ============================================================================

import Foundation
import SwiftData

enum DefaultCategories {
    struct CategoryData {
        let name: String
        let icon: String
        let colorHex: String
        let type: TransactionType
        let sortOrder: Int
        let seedIdentifier: String
    }

    static let all: [CategoryData] = expense + income

    static let expense: [CategoryData] = [
        .init(name: "飲食", icon: "fork.knife", colorHex: "#FF9800", type: .expense, sortOrder: 0, seedIdentifier: "default_expense_0"),
        .init(name: "交通", icon: "car.fill", colorHex: "#2196F3", type: .expense, sortOrder: 1, seedIdentifier: "default_expense_1"),
        .init(name: "娛樂", icon: "gamecontroller.fill", colorHex: "#9C27B0", type: .expense, sortOrder: 2, seedIdentifier: "default_expense_2"),
        .init(name: "購物", icon: "bag.fill", colorHex: "#E91E63", type: .expense, sortOrder: 3, seedIdentifier: "default_expense_3"),
        .init(name: "居住", icon: "house.fill", colorHex: "#795548", type: .expense, sortOrder: 4, seedIdentifier: "default_expense_4"),
        .init(name: "醫療", icon: "cross.case.fill", colorHex: "#F44336", type: .expense, sortOrder: 5, seedIdentifier: "default_expense_5"),
        .init(name: "教育", icon: "book.fill", colorHex: "#3F51B5", type: .expense, sortOrder: 6, seedIdentifier: "default_expense_6"),
        .init(name: "其他", icon: "ellipsis.circle.fill", colorHex: "#607D8B", type: .expense, sortOrder: 7, seedIdentifier: "default_expense_7"),
    ]

    static let income: [CategoryData] = [
        .init(name: "薪資", icon: "briefcase.fill", colorHex: "#4CAF50", type: .income, sortOrder: 0, seedIdentifier: "default_income_0"),
        .init(name: "獎金", icon: "star.fill", colorHex: "#FFC107", type: .income, sortOrder: 1, seedIdentifier: "default_income_1"),
        .init(name: "投資", icon: "chart.line.uptrend.xyaxis", colorHex: "#00BCD4", type: .income, sortOrder: 2, seedIdentifier: "default_income_2"),
        .init(name: "其他", icon: "ellipsis.circle.fill", colorHex: "#8BC34A", type: .income, sortOrder: 3, seedIdentifier: "default_income_3"),
    ]

    static func seed(into context: ModelContext) {
        let existingCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let existingIds = Set(existingCategories.map(\.seedIdentifier))

        for data in all {
            guard !existingIds.contains(data.seedIdentifier) else { continue }
            let category = Category(
                name: data.name,
                icon: data.icon,
                colorHex: data.colorHex,
                type: data.type,
                sortOrder: data.sortOrder,
                isDefault: true
            )
            category.seedIdentifier = data.seedIdentifier
            context.insert(category)
        }
    }

    struct AccountData {
        let name: String
        let type: AccountType
        let icon: String
        let colorHex: String
        let sortOrder: Int
        let seedIdentifier: String
    }

    static let defaultAccounts: [AccountData] = [
        .init(name: "現金", type: .cash, icon: "banknote.fill", colorHex: "#4CAF50", sortOrder: 0, seedIdentifier: "default_account_0"),
        .init(name: "銀行存款", type: .bank, icon: "building.columns.fill", colorHex: "#2196F3", sortOrder: 1, seedIdentifier: "default_account_1"),
        .init(name: "信用卡", type: .creditCard, icon: "creditcard.fill", colorHex: "#FF9800", sortOrder: 2, seedIdentifier: "default_account_2"),
    ]

    static func seedAccounts(into context: ModelContext) {
        let existingAccounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        let existingIds = Set(existingAccounts.map(\.seedIdentifier))

        for data in defaultAccounts {
            guard !existingIds.contains(data.seedIdentifier) else { continue }
            let account = Account(
                name: data.name,
                type: data.type,
                icon: data.icon,
                colorHex: data.colorHex,
                sortOrder: data.sortOrder,
                isDefault: true
            )
            account.seedIdentifier = data.seedIdentifier
            context.insert(account)
        }
    }
}
