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
//   - 提供 18 種預設支出分類（飲食、交通、娛樂、購物、居住、醫療、教育、通訊、服飾、日用品、旅遊、社交、美容、保險、運動、寵物、孝親、其他）
//   - 提供 9 種預設收入分類（薪資、獎金、投資、副業、利息、租金收入、禮金、退款、其他）
//   - 提供 4 個預設帳戶（現金、合庫、土銀、LinePay）
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
//   - defaultAccounts: 預設帳戶陣列（4 筆）
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
        .init(name: "通訊", icon: "iphone.gen3", colorHex: "#00BCD4", type: .expense, sortOrder: 7, seedIdentifier: "default_expense_8"),
        .init(name: "服飾", icon: "tshirt.fill", colorHex: "#AB47BC", type: .expense, sortOrder: 8, seedIdentifier: "default_expense_9"),
        .init(name: "日用品", icon: "basket.fill", colorHex: "#8D6E63", type: .expense, sortOrder: 9, seedIdentifier: "default_expense_10"),
        .init(name: "旅遊", icon: "airplane", colorHex: "#26C6DA", type: .expense, sortOrder: 10, seedIdentifier: "default_expense_11"),
        .init(name: "社交", icon: "person.2.fill", colorHex: "#EC407A", type: .expense, sortOrder: 11, seedIdentifier: "default_expense_12"),
        .init(name: "美容", icon: "sparkles", colorHex: "#FF7043", type: .expense, sortOrder: 12, seedIdentifier: "default_expense_13"),
        .init(name: "保險", icon: "shield.fill", colorHex: "#5C6BC0", type: .expense, sortOrder: 13, seedIdentifier: "default_expense_14"),
        .init(name: "運動", icon: "figure.run", colorHex: "#66BB6A", type: .expense, sortOrder: 14, seedIdentifier: "default_expense_15"),
        .init(name: "寵物", icon: "pawprint.fill", colorHex: "#FFCA28", type: .expense, sortOrder: 15, seedIdentifier: "default_expense_16"),
        .init(name: "孝親", icon: "heart.fill", colorHex: "#EF5350", type: .expense, sortOrder: 16, seedIdentifier: "default_expense_17"),
        .init(name: "其他", icon: "ellipsis.circle.fill", colorHex: "#607D8B", type: .expense, sortOrder: 17, seedIdentifier: "default_expense_7"),
    ]

    static let income: [CategoryData] = [
        .init(name: "薪資", icon: "briefcase.fill", colorHex: "#4CAF50", type: .income, sortOrder: 0, seedIdentifier: "default_income_0"),
        .init(name: "獎金", icon: "star.fill", colorHex: "#FFC107", type: .income, sortOrder: 1, seedIdentifier: "default_income_1"),
        .init(name: "投資", icon: "chart.line.uptrend.xyaxis", colorHex: "#00BCD4", type: .income, sortOrder: 2, seedIdentifier: "default_income_2"),
        .init(name: "副業", icon: "hammer.fill", colorHex: "#FF7043", type: .income, sortOrder: 3, seedIdentifier: "default_income_4"),
        .init(name: "利息", icon: "percent", colorHex: "#26A69A", type: .income, sortOrder: 4, seedIdentifier: "default_income_5"),
        .init(name: "租金收入", icon: "key.fill", colorHex: "#8D6E63", type: .income, sortOrder: 5, seedIdentifier: "default_income_6"),
        .init(name: "禮金", icon: "gift.fill", colorHex: "#EC407A", type: .income, sortOrder: 6, seedIdentifier: "default_income_7"),
        .init(name: "退款", icon: "arrow.uturn.backward.circle.fill", colorHex: "#78909C", type: .income, sortOrder: 7, seedIdentifier: "default_income_8"),
        .init(name: "其他", icon: "ellipsis.circle.fill", colorHex: "#8BC34A", type: .income, sortOrder: 8, seedIdentifier: "default_income_3"),
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
                isDefault: true,
                seedIdentifier: data.seedIdentifier
            )
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
        .init(name: "合庫", type: .bank, icon: "building.columns.fill", colorHex: "#2196F3", sortOrder: 1, seedIdentifier: "default_account_1"),
        .init(name: "土銀", type: .bank, icon: "building.columns.fill", colorHex: "#1565C0", sortOrder: 2, seedIdentifier: "default_account_2"),
        .init(name: "LinePay", type: .eWallet, icon: "iphone.gen3", colorHex: "#00C300", sortOrder: 3, seedIdentifier: "default_account_3"),
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
                isDefault: true,
                seedIdentifier: data.seedIdentifier
            )
            context.insert(account)
        }
    }

    static func removeDuplicates(from context: ModelContext) {
        let allCategories = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        var seenCategoryIds = Set<String>()
        for category in allCategories {
            guard !category.seedIdentifier.isEmpty else { continue }
            if seenCategoryIds.contains(category.seedIdentifier) {
                context.delete(category)
            } else {
                seenCategoryIds.insert(category.seedIdentifier)
            }
        }

        let allAccounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
        var seenAccountIds = Set<String>()
        for account in allAccounts {
            guard !account.seedIdentifier.isEmpty else { continue }
            if seenAccountIds.contains(account.seedIdentifier) {
                context.delete(account)
            } else {
                seenAccountIds.insert(account.seedIdentifier)
            }
        }
    }
}
