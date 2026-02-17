import Foundation
import SwiftData

@Model
final class Account {
    var name: String
    var type: AccountType
    var icon: String
    var colorHex: String
    var initialBalance: Decimal
    var sortOrder: Int
    var isDefault: Bool

    @Relationship(deleteRule: .nullify, inverse: \Transaction.account)
    var transactions: [Transaction]

    init(name: String, type: AccountType, icon: String, colorHex: String, initialBalance: Decimal = 0, sortOrder: Int = 0, isDefault: Bool = false) {
        self.name = name
        self.type = type
        self.icon = icon
        self.colorHex = colorHex
        self.initialBalance = initialBalance
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.transactions = []
    }

    var currentBalance: Decimal {
        let incomeTotal = transactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expenseTotal = transactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return initialBalance + incomeTotal - expenseTotal
    }
}
