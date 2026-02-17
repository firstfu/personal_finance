//
//  TransactionType.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense

    var displayName: String {
        switch self {
        case .income: "收入"
        case .expense: "支出"
        }
    }
}
