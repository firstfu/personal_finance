import Foundation
import SwiftData

@Model
final class Transaction {
    var amountString: String = "0"
    var type: TransactionType = TransactionType.expense
    var category: Category?
    var account: Account?
    var note: String = ""
    var date: Date = Date.now
    var createdAt: Date = Date.now
    var isDemoData: Bool = false
    var seedIdentifier: String = ""

    @Transient
    var amount: Decimal {
        get { Decimal(string: amountString) ?? 0 }
        set { amountString = "\(newValue)" }
    }

    init(amount: Decimal, type: TransactionType, category: Category? = nil, account: Account? = nil, note: String = "", date: Date = .now, isDemoData: Bool = false) {
        self.amountString = "\(amount)"
        self.type = type
        self.category = category
        self.account = account
        self.note = note
        self.date = date
        self.createdAt = .now
        self.isDemoData = isDemoData
    }
}
