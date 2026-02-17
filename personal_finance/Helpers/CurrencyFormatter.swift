//
//  CurrencyFormatter.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - CurrencyFormatter.swift
// 模組：Helpers
//
// 功能說明：
//   這個檔案提供統一的新台幣（TWD）貨幣格式化工具，將 Decimal 金額
//   轉換為帶有 NT$ 符號的格式化字串。
//
// 主要職責：
//   - 封裝 NumberFormatter 以統一貨幣顯示格式
//   - 提供 format(_:) 靜態方法將 Decimal 值格式化為 "NT$XX,XXX" 格式
//   - 設定貨幣代碼為 TWD、符號為 NT$、小數位數為 0
//
// 注意事項：
//   - NumberFormatter 以 private static let 快取，避免重複建立
//   - 格式化失敗時回傳預設值 "NT$0"
//   - 主 App 與 Widget 模組皆使用此工具進行金額顯示
// ============================================================================

import Foundation

enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "TWD"
        f.currencySymbol = "NT$"
        f.maximumFractionDigits = 0
        return f
    }()

    static func format(_ value: Decimal) -> String {
        formatter.string(from: value as NSDecimalNumber) ?? "NT$0"
    }
}
