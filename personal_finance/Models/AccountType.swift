// ============================================================================
// MARK: - AccountType.swift
// 模組：Models
//
// 功能說明：
//   定義帳戶類型的列舉，區分「現金」、「銀行存款」、「信用卡」與「電子支付」
//   四種帳戶類型。供 Account 模型使用，並提供各類型的預設圖示。
//
// 主要職責：
//   - 以 enum 定義四種帳戶類型
//   - 遵循 Codable 協定，支援 SwiftData 持久化序列化
//   - 遵循 CaseIterable 協定，方便 UI 中迭代所有選項
//   - 提供繁體中文顯示名稱（displayName）供 UI 使用
//   - 提供各類型的預設 SF Symbols 圖示名稱（defaultIcon）
//
// 關鍵屬性：
//   - cash: 現金帳戶，圖示為 "banknote.fill"
//   - bank: 銀行存款帳戶，圖示為 "building.columns.fill"
//   - creditCard: 信用卡帳戶，圖示為 "creditcard.fill"
//   - eWallet: 電子支付帳戶，圖示為 "iphone.gen3"
//   - displayName: 計算屬性，回傳繁體中文名稱
//   - defaultIcon: 計算屬性，回傳該類型的預設 SF Symbols 圖示名稱
//
// 注意事項：
//   - rawValue 為英文字串，用於資料儲存
//   - 顯示名稱為繁體中文，僅用於 UI 呈現
// ============================================================================

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
