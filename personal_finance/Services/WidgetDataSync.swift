// ============================================================================
// MARK: - WidgetDataSync.swift
// 模組：Services
//
// 功能說明：
//   這個檔案定義了 Widget 資料同步服務，負責從主 App 的 SwiftData 資料庫
//   中擷取當月財務摘要，並將快照資料寫入 App Group 共享容器，供 Widget
//   Extension 讀取顯示。
//
// 主要職責：
//   - 查詢當月所有交易記錄，計算月收入/月支出/月結餘
//   - 統計前三大支出分類及其佔比百分比
//   - 擷取最近 5 筆交易記錄供 Widget 顯示
//   - 擷取所有帳戶餘額摘要
//   - 將快照資料序列化為 JSON 並寫入 App Group 共享目錄
//   - 通知 WidgetCenter 重新載入所有時間線
//
// 關鍵方法：
//   - updateSnapshot(from:): 主要同步方法，從 ModelContext 讀取資料、
//     組裝 WidgetSnapshot、寫入 JSON 檔案並觸發 Widget 更新
//
// 關鍵屬性：
//   - appGroupID: App Group 識別碼 "group.com.firstfu.personal-finance"
//   - snapshotFileName: 快照檔案名稱 "widget_snapshot.json"
//   - snapshotURL: 快照檔案在 App Group 容器中的完整路徑
//
// 注意事項：
//   - 日期格式使用繁體中文地區設定（zh_TW），顯示月份為「X月」
//   - 金額以 String 格式儲存於快照中，保留 Decimal 精度
//   - 寫入檔案使用 .atomic 選項確保資料一致性
//   - 若 App Group 容器無法存取，方法會靜默返回
// ============================================================================

import Foundation
import SwiftData
import WidgetKit

enum WidgetDataSync {
    private static let appGroupID = "group.com.firstfu.personal-finance"
    private static let snapshotFileName = "widget_snapshot.json"

    private static var snapshotURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(snapshotFileName)
    }

    // MARK: - Write snapshot (called from App)

    static func updateSnapshot(from context: ModelContext) {
        guard let url = snapshotURL else { return }

        let calendar = Calendar.current
        let now = Date.now
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        let monthPredicate = #Predicate<Transaction> {
            $0.date >= startOfMonth && $0.date < endOfMonth
        }
        let descriptor = FetchDescriptor<Transaction>(
            predicate: monthPredicate,
            sortBy: [SortDescriptor(\Transaction.date, order: .reverse)]
        )

        guard let monthTransactions = try? context.fetch(descriptor) else { return }

        let monthlyIncome = monthTransactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let monthlyExpense = monthTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }

        // Top 3 expense categories
        let expenseTransactions = monthTransactions.filter { $0.type == .expense }
        var categoryTotals: [String: (name: String, icon: String, colorHex: String, total: Decimal)] = [:]
        for tx in expenseTransactions {
            let name = tx.category?.name ?? "其他"
            let icon = tx.category?.icon ?? "ellipsis.circle.fill"
            let colorHex = tx.category?.colorHex ?? "#607D8B"
            if var existing = categoryTotals[name] {
                existing.total += tx.amount
                categoryTotals[name] = existing
            } else {
                categoryTotals[name] = (name: name, icon: icon, colorHex: colorHex, total: tx.amount)
            }
        }
        let totalExpenseForPercent = monthlyExpense > 0 ? monthlyExpense : 1
        let topCategories = categoryTotals.values
            .sorted { $0.total > $1.total }
            .prefix(3)
            .map { cat in
                WidgetSnapshot.CategorySummary(
                    name: cat.name,
                    icon: cat.icon,
                    colorHex: cat.colorHex,
                    percentage: Double(truncating: (cat.total / totalExpenseForPercent * 100) as NSDecimalNumber)
                )
            }

        let recentTransactions = Array(monthTransactions.prefix(5)).map { tx in
            WidgetSnapshot.WidgetTransaction(
                categoryIcon: tx.category?.icon ?? "ellipsis.circle.fill",
                categoryName: tx.category?.name ?? "其他",
                note: tx.note,
                amountString: tx.amountString,
                isIncome: tx.type == .income
            )
        }

        let accountDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\Account.sortOrder)])
        let accounts = (try? context.fetch(accountDescriptor)) ?? []
        let accountSummaries = accounts.map { account in
            WidgetSnapshot.AccountSummary(
                name: account.name,
                icon: account.icon,
                balanceString: "\(account.currentBalance)"
            )
        }

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "zh_TW")
        monthFormatter.dateFormat = "M月"

        let totalBalance = accounts.reduce(Decimal.zero) { $0 + $1.currentBalance }

        let snapshot = WidgetSnapshot(
            date: now,
            monthlyIncomeString: "\(monthlyIncome)",
            monthlyExpenseString: "\(monthlyExpense)",
            monthlyBalanceString: "\(totalBalance)",
            topCategories: Array(topCategories),
            recentTransactions: recentTransactions,
            accounts: accountSummaries,
            displayMonth: monthFormatter.string(from: now)
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(snapshot) {
            try? data.write(to: url, options: .atomic)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }
}
