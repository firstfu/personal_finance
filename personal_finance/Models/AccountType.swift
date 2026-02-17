import Foundation

enum AccountType: String, Codable, CaseIterable {
    case cash
    case bank
    case creditCard
    case eWallet

    var displayName: String {
        switch self {
        case .cash: "現金"
        case .bank: "銀行存款"
        case .creditCard: "信用卡"
        case .eWallet: "電子支付"
        }
    }

    var defaultIcon: String {
        switch self {
        case .cash: "banknote.fill"
        case .bank: "building.columns.fill"
        case .creditCard: "creditcard.fill"
        case .eWallet: "iphone.gen3"
        }
    }
}
