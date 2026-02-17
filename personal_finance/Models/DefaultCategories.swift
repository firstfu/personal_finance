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
    }

    static let all: [CategoryData] = expense + income

    static let expense: [CategoryData] = [
        .init(name: "飲食", icon: "fork.knife", colorHex: "#FF9800", type: .expense, sortOrder: 0),
        .init(name: "交通", icon: "car.fill", colorHex: "#2196F3", type: .expense, sortOrder: 1),
        .init(name: "娛樂", icon: "gamecontroller.fill", colorHex: "#9C27B0", type: .expense, sortOrder: 2),
        .init(name: "購物", icon: "bag.fill", colorHex: "#E91E63", type: .expense, sortOrder: 3),
        .init(name: "居住", icon: "house.fill", colorHex: "#795548", type: .expense, sortOrder: 4),
        .init(name: "醫療", icon: "cross.case.fill", colorHex: "#F44336", type: .expense, sortOrder: 5),
        .init(name: "教育", icon: "book.fill", colorHex: "#3F51B5", type: .expense, sortOrder: 6),
        .init(name: "其他", icon: "ellipsis.circle.fill", colorHex: "#607D8B", type: .expense, sortOrder: 7),
    ]

    static let income: [CategoryData] = [
        .init(name: "薪資", icon: "briefcase.fill", colorHex: "#4CAF50", type: .income, sortOrder: 0),
        .init(name: "獎金", icon: "star.fill", colorHex: "#FFC107", type: .income, sortOrder: 1),
        .init(name: "投資", icon: "chart.line.uptrend.xyaxis", colorHex: "#00BCD4", type: .income, sortOrder: 2),
        .init(name: "其他", icon: "ellipsis.circle.fill", colorHex: "#8BC34A", type: .income, sortOrder: 3),
    ]

    static func seed(into context: ModelContext) {
        let descriptor = FetchDescriptor<Category>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for data in all {
            let category = Category(
                name: data.name,
                icon: data.icon,
                colorHex: data.colorHex,
                type: data.type,
                sortOrder: data.sortOrder,
                isDefault: true
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
    }

    static let defaultAccounts: [AccountData] = [
        .init(name: "現金", type: .cash, icon: "banknote.fill", colorHex: "#4CAF50", sortOrder: 0),
        .init(name: "銀行存款", type: .bank, icon: "building.columns.fill", colorHex: "#2196F3", sortOrder: 1),
        .init(name: "信用卡", type: .creditCard, icon: "creditcard.fill", colorHex: "#FF9800", sortOrder: 2),
    ]

    static func seedAccounts(into context: ModelContext) {
        let descriptor = FetchDescriptor<Account>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        guard count == 0 else { return }

        for data in defaultAccounts {
            let account = Account(
                name: data.name,
                type: data.type,
                icon: data.icon,
                colorHex: data.colorHex,
                sortOrder: data.sortOrder,
                isDefault: true
            )
            context.insert(account)
        }
    }
}
