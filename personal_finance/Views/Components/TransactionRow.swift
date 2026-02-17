//
//  TransactionRow.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - TransactionRow.swift
// 模組：Views/Components
//
// 功能說明：
//   單筆交易列表項元件，用於在首頁的「最近交易」區塊中顯示
//   每一筆交易的摘要資訊，包含分類圖示、名稱、備註、金額、日期與帳戶。
//
// 主要職責：
//   - 顯示交易所屬分類的圖示與顏色圓形背景
//   - 顯示分類名稱與備註（備註限一行顯示）
//   - 顯示金額（收入為綠色帶「+」前綴，支出為紅色帶「-」前綴）
//   - 顯示交易日期（繁體中文月日格式）
//   - 顯示所屬帳戶名稱
//
// UI 結構：
//   - 左側圓形圖示: 分類顏色淡背景 + 分類 SF Symbol 圖示
//   - 中間文字區:
//     - 分類名稱（無分類時顯示「未分類」）
//     - 備註文字（選填，caption 字級，單行截斷）
//   - 右側資訊區:
//     - 金額（粗體，顏色依收入/支出區分）
//     - 日期（caption 字級，zh-TW 格式）
//     - 帳戶名稱（caption2 字級）
//
// 資料依賴：
//   - transaction: Transaction（由父視圖傳入的單筆交易物件）
//   - 透過 transaction.category 取得分類資訊（可能為 nil）
//   - 透過 transaction.account 取得帳戶名稱（可能為 nil）
//
// 注意事項：
//   - 當交易未關聯分類時，圖示顯示 questionmark.circle，顏色為灰色
//   - 金額格式化使用 CurrencyFormatter.format()，並在前方加上 +/- 符號
//   - 此為純展示元件，不包含任何互動行為（無點擊、無滑動）
// ============================================================================

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    private var isTransfer: Bool {
        transaction.type == .transfer
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill((isTransfer ? AppTheme.primary : categoryColor).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: isTransfer ? "arrow.left.arrow.right" : (transaction.category?.icon ?? "questionmark.circle"))
                    .foregroundStyle(isTransfer ? AppTheme.primary : categoryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(isTransfer ? "轉帳" : (transaction.category?.name ?? "未分類"))
                    .font(.body)
                    .foregroundStyle(AppTheme.onBackground)
                if isTransfer {
                    Text(transferSubtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                } else if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(amountText)
                    .font(.body.bold())
                    .foregroundStyle(amountColor)
                Text(transaction.date, format: .dateTime.month().day().locale(Locale(identifier: "zh-TW")))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                if !isTransfer, let accountName = transaction.account?.name {
                    Text(accountName)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        guard let hex = transaction.category?.colorHex else { return .gray }
        return Color(hex: hex)
    }

    private var transferSubtitle: String {
        let from = transaction.account?.name ?? "未知帳戶"
        let to = transaction.transferToAccount?.name ?? "未知帳戶"
        return "\(from) → \(to)"
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income: AppTheme.income
        case .expense: AppTheme.expense
        case .transfer: AppTheme.primary
        }
    }

    private var amountText: String {
        switch transaction.type {
        case .income:
            return "+" + CurrencyFormatter.format(transaction.amount)
        case .expense:
            return "-" + CurrencyFormatter.format(transaction.amount)
        case .transfer:
            return CurrencyFormatter.format(transaction.amount)
        }
    }
}
