//
//  personal_financeTests.swift
//  personal_financeTests
//
//  Created by firstfu on 2026/2/17.
//

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

    @Test func accountTypeDisplayName() async throws {
        #expect(AccountType.cash.displayName == "現金")
        #expect(AccountType.bank.displayName == "銀行存款")
        #expect(AccountType.creditCard.displayName == "信用卡")
        #expect(AccountType.eWallet.displayName == "電子支付")
    }
}
