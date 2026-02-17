// ============================================================================
// MARK: - LargeWidgetView.swift
// 模組：Widget/Views
//
// 功能說明：
//   這個檔案定義了大尺寸（systemLarge）Widget 的視圖佈局，
//   完整顯示月收支摘要、最近交易紀錄以及帳戶餘額三個區塊。
//
// 主要職責：
//   - summarySection：顯示本月餘額、收入與支出摘要（含月份標示）
//   - transactionsSection：列出最近交易紀錄（含分類圖示、名稱、備註與金額）
//   - accountsSection：水平排列各帳戶名稱與餘額
//   - 三個區塊以 Divider 分隔，使用品牌綠色漸層背景
//
// 注意事項：
//   - 收入金額顯示為綠色（#C8E6C9），支出金額顯示為紅色（#FFCDD2）
//   - 各區塊在無資料時顯示對應的佔位提示文字
//   - 依賴 CurrencyFormatter 與 Color+Hex 擴展
// ============================================================================

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    @Environment(\.colorScheme) private var colorScheme
    let entry: FinanceWidgetEntry

    var body: some View {
        VStack(spacing: 0) {
            summarySection
                .padding(.bottom, 10)

            Divider()
                .overlay(Color.white.opacity(0.2))

            transactionsSection
                .padding(.vertical, 6)

            Divider()
                .overlay(Color.white.opacity(0.2))

            accountsSection
                .padding(.top, 6)
        }
        .containerBackground(for: .widget) {
            if colorScheme == .dark {
                Color(.systemBackground)
            } else {
                LinearGradient(
                    colors: [Color(hex: "#8BC34A"), Color(hex: "#2E7D32")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
        .widgetURL(URL(string: "personalfinance://home"))
    }

    private var summarySection: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.caption)
                Text("本月收支摘要")
                    .font(.caption)
                Spacer()
                Text(entry.displayMonth)
                    .font(.caption)
            }
            .foregroundStyle(.white.opacity(0.85))

            HStack(alignment: .firstTextBaseline) {
                Text(CurrencyFormatter.format(entry.monthlyBalance))
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("本月餘額")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 10))
                    Text(CurrencyFormatter.format(entry.monthlyIncome))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 10))
                    Text(CurrencyFormatter.format(entry.monthlyExpense))
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)

                Spacer()
            }
        }
    }

    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最近交易")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            if entry.recentTransactions.isEmpty {
                Text("尚無交易紀錄")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                ForEach(Array(entry.recentTransactions.enumerated()), id: \.offset) { _, tx in
                    HStack(spacing: 8) {
                        Image(systemName: tx.categoryIcon)
                            .font(.system(size: 12))
                            .foregroundStyle(.white)
                            .frame(width: 20)
                        Text(tx.categoryName)
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.9))
                        if !tx.note.isEmpty {
                            Text(tx.note)
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.6))
                                .lineLimit(1)
                        }
                        Spacer()
                        Text("\(tx.isIncome ? "+" : "-")\(CurrencyFormatter.format(tx.amount))")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(tx.isIncome ? Color(hex: "#C8E6C9") : Color(hex: "#FFCDD2"))
                            .lineLimit(1)
                    }
                }
            }
        }
    }

    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("帳戶餘額")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            if entry.accounts.isEmpty {
                Text("尚無帳戶")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                HStack(spacing: 12) {
                    ForEach(Array(entry.accounts.enumerated()), id: \.offset) { _, account in
                        HStack(spacing: 4) {
                            Image(systemName: account.icon)
                                .font(.system(size: 10))
                            Text(account.name)
                                .font(.system(size: 10))
                            Text(CurrencyFormatter.format(account.balance))
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                        }
                        .foregroundStyle(.white.opacity(0.9))
                    }
                    Spacer()
                }
            }
        }
    }
}
