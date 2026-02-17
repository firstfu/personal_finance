//
//  personal_financeTests.swift
//  personal_financeTests
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - personal_financeTests.swift
// 模組：Tests
//
// 功能說明：
//   這個檔案包含應用程式核心資料模型的單元測試，使用 Swift Testing
//   框架驗證 Category、Transaction、Account 等 Model 的初始化與基本行為。
//
// 主要職責：
//   - CategoryTests：測試分類初始化屬性、交易類型顯示名稱
//   - TransactionTests：測試交易初始化屬性、交易與分類的關聯
//   - AccountTests：測試帳戶初始化屬性、帳戶類型顯示名稱
//
// 注意事項：
//   - 使用 Swift Testing 框架（@Test、#expect），非 XCTest
//   - 透過 @testable import personal_finance 存取內部型別
//   - 測試不涉及 SwiftData 持久化，僅驗證 Model 物件的記憶體狀態
// ============================================================================

import Testing
import Foundation
@testable import personal_finance

struct CategoryTests {
    @Test func categoryInitialization() async throws {
        let category = Category(
            name: "飲食",
            icon: "fork.knife",
            colorHex: "#FF9800",
            type: .expense,
            sortOrder: 0,
            isDefault: true
        )
        #expect(category.name == "飲食")
        #expect(category.icon == "fork.knife")
        #expect(category.colorHex == "#FF9800")
        #expect(category.type == .expense)
        #expect(category.sortOrder == 0)
        #expect(category.isDefault == true)
    }

    @Test func categorySeedIdentifier() async throws {
        let category = Category(
            name: "飲食",
            icon: "fork.knife",
            colorHex: "#FF9800",
            type: .expense,
            sortOrder: 0,
            isDefault: true,
            seedIdentifier: "default_expense_0"
        )
        #expect(category.seedIdentifier == "default_expense_0")
    }

    @Test func transactionTypeDisplayName() async throws {
        #expect(TransactionType.income.displayName == "收入")
        #expect(TransactionType.expense.displayName == "支出")
    }
}

struct TransactionTests {
    @Test func transactionInitialization() async throws {
        let tx = Transaction(amount: 150, type: .expense, note: "午餐")
        #expect(tx.amount == 150)
        #expect(tx.type == .expense)
        #expect(tx.note == "午餐")
        #expect(tx.category == nil)
    }

    @Test func transactionWithCategory() async throws {
        let cat = Category(name: "飲食", icon: "fork.knife", colorHex: "#FF9800", type: .expense, sortOrder: 0)
        let tx = Transaction(amount: 250, type: .expense, category: cat, note: "晚餐")
        #expect(tx.category?.name == "飲食")
    }
}

struct AccountTests {
    @Test func accountInitialization() async throws {
        let account = Account(name: "現金", type: .cash, icon: "banknote.fill", colorHex: "#4CAF50", initialBalance: 10000)
        #expect(account.name == "現金")
        #expect(account.type == .cash)
        #expect(account.initialBalance == 10000)
    }

    @Test func accountSeedIdentifier() async throws {
        let account = Account(
            name: "現金",
            type: .cash,
            icon: "banknote.fill",
            colorHex: "#4CAF50",
            seedIdentifier: "default_account_0"
        )
        #expect(account.seedIdentifier == "default_account_0")
    }

    @Test func accountTypeDisplayName() async throws {
        #expect(AccountType.cash.displayName == "現金")
        #expect(AccountType.bank.displayName == "銀行存款")
        #expect(AccountType.creditCard.displayName == "信用卡")
        #expect(AccountType.eWallet.displayName == "電子支付")
    }
}
