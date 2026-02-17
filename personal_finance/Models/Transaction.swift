//
//  Transaction.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import Foundation
import SwiftData

@Model
final class Transaction {
    var amount: Decimal
    var type: TransactionType
    var category: Category?
    var note: String
    var date: Date
    var createdAt: Date

    init(amount: Decimal, type: TransactionType, category: Category? = nil, note: String = "", date: Date = .now) {
        self.amount = amount
        self.type = type
        self.category = category
        self.note = note
        self.date = date
        self.createdAt = .now
    }
}
