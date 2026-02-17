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
