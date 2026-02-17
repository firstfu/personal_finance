import Foundation

// Codable snapshot model shared between App and Widget targets.
// The App writes this JSON via WidgetDataSync.updateSnapshot(),
// and the Widget reads it via WidgetSnapshot.load().

struct WidgetSnapshot: Codable {
    let date: Date
    let monthlyIncomeString: String
    let monthlyExpenseString: String
    let monthlyBalanceString: String
    let topCategories: [CategorySummary]
    let recentTransactions: [WidgetTransaction]
    let accounts: [AccountSummary]
    let displayMonth: String

    var monthlyIncome: Decimal { Decimal(string: monthlyIncomeString) ?? 0 }
    var monthlyExpense: Decimal { Decimal(string: monthlyExpenseString) ?? 0 }
    var monthlyBalance: Decimal { Decimal(string: monthlyBalanceString) ?? 0 }

    struct CategorySummary: Codable {
        let name: String
        let icon: String
        let colorHex: String
        let percentage: Double
    }

    struct WidgetTransaction: Codable {
        let categoryIcon: String
        let categoryName: String
        let note: String
        let amountString: String
        let isIncome: Bool

        var amount: Decimal { Decimal(string: amountString) ?? 0 }
    }

    struct AccountSummary: Codable {
        let name: String
        let icon: String
        let balanceString: String

        var balance: Decimal { Decimal(string: balanceString) ?? 0 }
    }

    // MARK: - Load from App Group (used by Widget)

    static func load() -> WidgetSnapshot? {
        let appGroupID = "group.com.firstfu.personal-finance"
        let snapshotFileName = "widget_snapshot.json"
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(snapshotFileName),
              let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}
