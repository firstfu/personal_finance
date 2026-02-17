//
//  AnalyticsView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]

    @State private var selectedPeriod: Period = .month

    enum Period: String, CaseIterable {
        case week = "本週"
        case month = "本月"
        case year = "本年"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    periodPicker
                    spendingSummaryCard
                    expenseTrendChart
                    categoryBreakdown
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
            }
            .navigationTitle("分析")
            .background(Color(.systemBackground))
        }
    }

    private var filteredTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date.now
        let start: Date
        switch selectedPeriod {
        case .week:
            start = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        case .month:
            start = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        case .year:
            start = calendar.date(from: calendar.dateComponents([.year], from: now))!
        }
        return allTransactions.filter { $0.date >= start }
    }

    private var expenses: [Transaction] {
        filteredTransactions.filter { $0.type == .expense }
    }

    private var totalExpense: Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var periodPicker: some View {
        Picker("期間", selection: $selectedPeriod) {
            ForEach(Period.allCases, id: \.self) { period in
                Text(period.rawValue).tag(period)
            }
        }
        .pickerStyle(.segmented)
    }

    private var spendingSummaryCard: some View {
        VStack(spacing: 8) {
            Text("總支出")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)
            Text(CurrencyFormatter.format(totalExpense))
                .font(AppTheme.amountFont)
                .foregroundStyle(AppTheme.expense)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var expenseTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支出趨勢")
                .font(.headline)

            if expenses.isEmpty {
                Text("尚無資料")
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    ForEach(dailyExpenses, id: \.date) { data in
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("金額", data.total)
                        )
                        .foregroundStyle(AppTheme.primary)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("金額", data.total)
                        )
                        .foregroundStyle(AppTheme.primary.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var dailyExpenses: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped.map { (date: $0.key, total: NSDecimalNumber(decimal: $0.value.reduce(0) { $0 + $1.amount }).doubleValue) }
            .sorted { $0.date < $1.date }
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分類比例")
                .font(.headline)

            if expenses.isEmpty {
                Text("尚無資料")
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                Chart(categoryData, id: \.name) { item in
                    SectorMark(
                        angle: .value("金額", item.total),
                        innerRadius: .ratio(0.5),
                        angularInset: 1
                    )
                    .foregroundStyle(Color(hex: item.colorHex))
                }
                .frame(height: 200)

                ForEach(categoryData, id: \.name) { item in
                    HStack {
                        Circle()
                            .fill(Color(hex: item.colorHex))
                            .frame(width: 10, height: 10)
                        Text(item.name)
                            .font(.body)
                        Spacer()
                        Text(CurrencyFormatter.format(item.total))
                            .font(.body.monospacedDigit())
                        Text(String(format: "%.0f%%", item.percentage))
                            .font(.caption)
                            .foregroundStyle(AppTheme.secondaryText)
                            .frame(width: 40, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var categoryData: [(name: String, colorHex: String, total: Decimal, percentage: Double)] {
        let grouped = Dictionary(grouping: expenses) { $0.category?.name ?? "未分類" }
        let total = totalExpense
        guard total > 0 else { return [] }
        return grouped.map { key, txs in
            let sum = txs.reduce(Decimal.zero) { $0 + $1.amount }
            let colorHex = txs.first?.category?.colorHex ?? "#607D8B"
            let pct = NSDecimalNumber(decimal: sum / total * 100).doubleValue
            return (name: key, colorHex: colorHex, total: sum, percentage: pct)
        }
        .sorted { $0.total > $1.total }
    }
}
