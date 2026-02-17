import Foundation
import SwiftData

@Model
final class Account {
    var name: String = ""
    var type: AccountType = AccountType.cash
    var icon: String = ""
    var colorHex: String = "#000000"
    var initialBalanceString: String = "0"
    var sortOrder: Int = 0
    var isDefault: Bool = false
    var seedIdentifier: String = ""

    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    var transactions: [Transaction]? = []

    @Transient
    var initialBalance: Decimal {
        get { Decimal(string: initialBalanceString) ?? 0 }
        set { initialBalanceString = "\(newValue)" }
    }

    init(name: String, type: AccountType, icon: String, colorHex: String, initialBalance: Decimal = 0, sortOrder: Int = 0, isDefault: Bool = false) {
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.initialBalanceString = "\(initialBalance)"
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.transactions = []
    }

    var currentBalance: Decimal {
        let allTransactions = transactions ?? []
        let incomeTotal = allTransactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expenseTotal = allTransactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return initialBalance + incomeTotal - expenseTotal
    }
}
