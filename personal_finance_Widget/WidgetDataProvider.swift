// ============================================================================
// MARK: - WidgetDataProvider.swift
// 模組：Widget
//
// 功能說明：
//   這個檔案負責從本地快照檔案讀取資料並轉換為 Widget 可用的
//   FinanceWidgetEntry 格式，作為 Widget 與主 App 之間的資料橋接層。
//
// 主要職責：
//   - fetchEntry()：從 WidgetSnapshot 載入最新的財務快照資料
//   - 將 WidgetSnapshot 中的分類摘要、最近交易、帳戶餘額等資料
//     轉換為 FinanceWidgetEntry 的對應子結構
//   - 當快照載入失敗時回傳 placeholder 預設資料
//
// 注意事項：
//   - 資料來源為 WidgetSnapshot（由主 App 透過 WidgetDataSync 寫入）
//   - 此檔案不直接存取 SwiftData，僅讀取序列化後的快照
// ============================================================================

import Foundation

enum WidgetDataProvider {
    static func fetchEntry() -> FinanceWidgetEntry {
        guard let snapshot = WidgetSnapshot.load() else {
            return .placeholder
        }

        let topCategories = snapshot.topCategories.map { cat in
            FinanceWidgetEntry.CategorySummary(
                name: cat.name,
                icon: cat.icon,
                colorHex: cat.colorHex,
                percentage: cat.percentage
            )
        }

        let recentTransactions = snapshot.recentTransactions.map { tx in
            FinanceWidgetEntry.WidgetTransaction(
                categoryIcon: tx.categoryIcon,
                categoryName: tx.categoryName,
                note: tx.note,
                amount: tx.amount,
                isIncome: tx.isIncome
            )
        }

        let accountSummaries = snapshot.accounts.map { account in
            FinanceWidgetEntry.AccountSummary(
                name: account.name,
                icon: account.icon,
                balance: account.balance
            )
        }

        return FinanceWidgetEntry(
            date: snapshot.date,
            monthlyIncome: snapshot.monthlyIncome,
            monthlyExpense: snapshot.monthlyExpense,
            monthlyBalance: snapshot.monthlyBalance,
            topCategories: topCategories,
            recentTransactions: recentTransactions,
            accounts: accountSummaries,
            displayMonth: snapshot.displayMonth
        )
    }
}
