//
//  TransactionType.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - TransactionType.swift
// 模組：Models
//
// 功能說明：
//   定義交易類型的列舉，區分「收入」與「支出」兩種基本交易方向。
//   此列舉貫穿整個應用程式，用於交易記錄、分類篩選與統計分析。
//
// 主要職責：
//   - 以 enum 定義收入（income）與支出（expense）兩種交易類型
//   - 遵循 Codable 協定，支援 SwiftData 持久化序列化
//   - 遵循 CaseIterable 協定，方便 UI 中迭代所有選項
//   - 提供繁體中文顯示名稱（displayName），供 UI 直接使用
//
// 關鍵屬性：
//   - income: 收入類型，顯示名稱為「收入」
//   - expense: 支出類型，顯示名稱為「支出」
//   - displayName: 計算屬性，回傳對應的繁體中文名稱
//
// 注意事項：
//   - rawValue 為英文字串（"income" / "expense"），用於資料儲存
//   - 顯示名稱為繁體中文，僅用於 UI 呈現
// ============================================================================

import Foundation

enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense
    case transfer
    case adjustment

    var displayName: String {
        switch self {
        case .income: "收入"
        case .expense: "支出"
        case .transfer: "轉帳"
        case .adjustment: "餘額調整"
        }
    }
}
