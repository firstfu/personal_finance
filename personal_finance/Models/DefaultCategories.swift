//
//  DefaultCategories.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

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
