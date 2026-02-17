// ============================================================================
// MARK: - SmallWidgetView.swift
// 模組：Widget/Views
//
// 功能說明：
//   這個檔案定義了小尺寸（systemSmall）Widget 的視圖佈局，
//   以精簡方式顯示本月餘額、收入與支出摘要。
//
// 主要職責：
//   - 顯示本月餘額金額（大字體，自動縮放）
//   - 底部並排顯示收入與支出摘要數字
//   - 使用品牌綠色漸層作為背景
//   - 設定 widgetURL 以支援點擊跳轉至主 App 首頁
//
// 注意事項：
//   - 金額文字使用 minimumScaleFactor(0.6) 確保在小空間中自動縮放
//   - 背景漸層色碼與 AppTheme.primaryGradient 一致（#8BC34A -> #2E7D32）
//   - 依賴 CurrencyFormatter 進行金額格式化
// ============================================================================

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: FinanceWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.caption)
                Text("本月餘額")
                    .font(.caption)
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.85))

            Spacer()

            Text(CurrencyFormatter.format(entry.monthlyBalance))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 8))
                        Text("收入")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    Text(CurrencyFormatter.format(entry.monthlyIncome))
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 8))
                        Text("支出")
                            .font(.system(size: 9))
                    }
                    .foregroundStyle(.white.opacity(0.7))
                    Text(CurrencyFormatter.format(entry.monthlyExpense))
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(hex: "#8BC34A"), Color(hex: "#2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(URL(string: "personalfinance://home"))
    }
}
