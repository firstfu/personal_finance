//
//  MonthlySummaryCard.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - MonthlySummaryCard.swift
// 模組：Views/Components
//
// 功能說明：
//   本月收支摘要卡片元件，以醒目的漸層背景卡片呈現當月的
//   餘額、收入與支出總額，是首頁（HomeView）的核心視覺元件。
//
// 主要職責：
//   - 顯示本月餘額（balance = 收入 - 支出）
//   - 顯示本月總收入與總支出明細
//   - 提供統一的品牌漸層卡片視覺風格
//
// UI 結構：
//   - 頂部「本月餘額」標題文字（白色半透明）
//   - 中央餘額金額（大字體白色，使用 CurrencyFormatter 格式化）
//   - 底部收入/支出並排:
//     - 左側: 上箭頭圖示 +「收入」標籤 + 收入金額
//     - 右側: 下箭頭圖示 +「支出」標籤 + 支出金額
//   - 整體使用 AppTheme.primaryGradient 漸層背景與圓角矩形裁切
//
// 資料依賴：
//   - balance: Decimal（本月餘額，由父視圖計算傳入）
//   - totalIncome: Decimal（本月總收入，由父視圖計算傳入）
//   - totalExpense: Decimal（本月總支出，由父視圖計算傳入）
//
// 注意事項：
//   - 此為純展示元件，不直接查詢資料，所有數值由父視圖傳入
//   - 所有文字與圖示皆為白色系，適配漸層背景
//   - 金額格式化統一使用 CurrencyFormatter.format()
// ============================================================================

import SwiftUI

struct MonthlySummaryCard: View {
    var title: String = "本月餘額"
    let balance: Decimal
    let totalIncome: Decimal
    let totalExpense: Decimal

    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(AppTheme.captionFont)
                .foregroundStyle(.white.opacity(0.8))

            Text(CurrencyFormatter.format(balance))
                .font(AppTheme.amountFont)
                .foregroundStyle(.white)

            HStack(spacing: 24) {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                        Text("收入")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    Text(CurrencyFormatter.format(totalIncome))
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("支出")
                    }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    Text(CurrencyFormatter.format(totalExpense))
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(AppTheme.primaryGradient)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }
}
