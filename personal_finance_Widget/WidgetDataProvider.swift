import Foundation
import SwiftData

enum WidgetDataProvider {
    static func fetchEntry() -> FinanceWidgetEntry {
        let schema = Schema([
            Transaction.self,
            Category.self,
            Account.self,
        ])

        let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.firstfu.personal-finance")!
            .appending(path: "default.store")

        let config = ModelConfiguration(
            schema: schema,
            url: appGroupURL,
            allowsSave: false
        )

        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            return .placeholder
        }

        let context = ModelContext(container)
        context.autosaveEnabled = false

        let calendar = Calendar.current
        let now = Date.now
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!

        let monthPredicate = #Predicate<Transaction> {
            $0.date >= startOfMonth && $0.date < endOfMonth
        }
        var descriptor = FetchDescriptor<Transaction>(
            predicate: monthPredicate,
            sortBy: [SortDescriptor(\Transaction.date, order: .reverse)]
        )

        guard let monthTransactions = try? context.fetch(descriptor) else {
            return .placeholder
        }

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
            let key = name
            if var existing = categoryTotals[key] {
                existing.total += tx.amount
                categoryTotals[key] = existing
            } else {
                categoryTotals[key] = (name: name, icon: icon, colorHex: colorHex, total: tx.amount)
            }
        }
        let totalExpenseForPercent = monthlyExpense > 0 ? monthlyExpense : 1
        let topCategories = categoryTotals.values
            .sorted { $0.total > $1.total }
            .prefix(3)
            .map { cat in
                FinanceWidgetEntry.CategorySummary(
                    name: cat.name,
                    icon: cat.icon,
                    colorHex: cat.colorHex,
                    percentage: Double(truncating: (cat.total / totalExpenseForPercent * 100) as NSDecimalNumber)
                )
            }

        let recentTransactions = Array(monthTransactions.prefix(5)).map { tx in
            FinanceWidgetEntry.WidgetTransaction(
                categoryIcon: tx.category?.icon ?? "ellipsis.circle.fill",
                categoryName: tx.category?.name ?? "其他",
                note: tx.note,
                amount: tx.amount,
                isIncome: tx.type == .income
            )
        }

        let accountDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\Account.sortOrder)])
        let accounts = (try? context.fetch(accountDescriptor)) ?? []
        let accountSummaries = accounts.map { account in
            FinanceWidgetEntry.AccountSummary(
                name: account.name,
                icon: account.icon,
                balance: account.currentBalance
            )
        }

        let monthFormatter = DateFormatter()
        monthFormatter.locale = Locale(identifier: "zh_TW")
        monthFormatter.dateFormat = "M月"

        return FinanceWidgetEntry(
            date: now,
            monthlyIncome: monthlyIncome,
            monthlyExpense: monthlyExpense,
            monthlyBalance: monthlyIncome - monthlyExpense,
            topCategories: topCategories,
            recentTransactions: recentTransactions,
            accounts: accountSummaries,
            displayMonth: monthFormatter.string(from: now)
        )
    }
}
