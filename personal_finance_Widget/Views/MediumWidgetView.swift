// ============================================================================
// MARK: - MediumWidgetView.swift
// 模組：Widget/Views
//
// 功能說明：
//   這個檔案定義了中尺寸（systemMedium）Widget 的視圖佈局，
//   左側顯示月收支摘要，右側顯示支出分類排行榜。
//
// 主要職責：
//   - 左半部：顯示本月餘額、收入與支出摘要（含月份標示）
//   - 右半部：顯示前三名支出分類及其百分比（含色彩圓點與圖示）
//   - 無資料時顯示「尚無資料」佔位文字
//   - 使用品牌綠色漸層背景與 widgetURL 深層連結
//
// 注意事項：
//   - 左右區域使用 HStack(spacing: 0) 平分寬度
//   - 分類色彩透過 Color(hex:) 動態解析
//   - 依賴 CurrencyFormatter 與 Color+Hex 擴展
// ============================================================================

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: FinanceWidgetEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: Summary
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                    Text("本月收支")
                        .font(.caption)
                    Spacer()
                    Text(entry.displayMonth)
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.85))

                Text(CurrencyFormatter.format(entry.monthlyBalance))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("本月餘額")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))

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
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: Top categories
            VStack(alignment: .leading, spacing: 6) {
                Text("支出分類")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))

                if entry.topCategories.isEmpty {
                    Text("尚無資料")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    ForEach(Array(entry.topCategories.enumerated()), id: \.offset) { _, cat in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: 8, height: 8)
                            Image(systemName: cat.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(.white)
                            Text(cat.name)
                                .font(.system(size: 11))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(cat.percentage))%")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
