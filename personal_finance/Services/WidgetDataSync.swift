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

        let snapshot = WidgetSnapshot(
            date: now,
            monthlyIncomeString: "\(monthlyIncome)",
            monthlyExpenseString: "\(monthlyExpense)",
            monthlyBalanceString: "\(monthlyIncome - monthlyExpense)",
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
