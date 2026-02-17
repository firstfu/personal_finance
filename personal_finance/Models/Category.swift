//
//  Category.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import Foundation
import SwiftData

@Model
final class Category {
    var name: String
    var icon: String
    var colorHex: String
    var type: TransactionType
    var sortOrder: Int
    var isDefault: Bool

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]

    init(name: String, icon: String, colorHex: String, type: TransactionType, sortOrder: Int, isDefault: Bool = false) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.type = type
        self.sortOrder = sortOrder
        self.isDefault = isDefault
        self.transactions = []
    }
}
