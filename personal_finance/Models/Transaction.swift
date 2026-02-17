import Foundation
import SwiftData

@Model
final class Transaction {
    var amount: Decimal
    var type: TransactionType
    var category: Category?
    var account: Account?
    var note: String
    var date: Date
    var createdAt: Date

    init(amount: Decimal, type: TransactionType, category: Category? = nil, account: Account? = nil, note: String = "", date: Date = .now) {
        self.amount = amount
        self.type = type
        self.category = category
        self.account = account
        self.note = note
        self.date = date
        self.createdAt = .now
    }
}
