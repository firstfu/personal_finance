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
    @State private var selectedDate: Date?
    @State private var selectedCategoryAngle: Double?

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

    private var incomes: [Transaction] {
        filteredTransactions.filter { $0.type == .income }
    }

    private var totalExpense: Decimal {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var totalIncome: Decimal {
        incomes.reduce(0) { $0 + $1.amount }
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
        VStack(spacing: 12) {
            HStack {
                VStack(spacing: 4) {
                    Text("總支出")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(CurrencyFormatter.format(totalExpense))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(AppTheme.expense)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("總收入")
                        .font(AppTheme.captionFont)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(CurrencyFormatter.format(totalIncome))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(AppTheme.income)
                }
                .frame(maxWidth: .infinity)
            }

            Divider()

            VStack(spacing: 4) {
                Text("淨額")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
                let net = totalIncome - totalExpense
                Text(CurrencyFormatter.format(net))
                    .font(AppTheme.amountFont)
                    .foregroundStyle(net >= 0 ? AppTheme.income : AppTheme.expense)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var expenseTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("收支趨勢")
                .font(.headline)

            if expenses.isEmpty && incomes.isEmpty {
                Text("尚無資料")
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    ForEach(dailyExpenses, id: \.date) { data in
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("金額", data.total),
                            series: .value("類型", "支出")
                        )
                        .foregroundStyle(AppTheme.expense)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("金額", data.total),
                            series: .value("類型", "支出")
                        )
                        .foregroundStyle(AppTheme.expense.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }

                    ForEach(dailyIncomes, id: \.date) { data in
                        LineMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("金額", data.total),
                            series: .value("類型", "收入")
                        )
                        .foregroundStyle(AppTheme.income)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("日期", data.date, unit: .day),
                            y: .value("金額", data.total),
                            series: .value("類型", "收入")
                        )
                        .foregroundStyle(AppTheme.income.opacity(0.1))
                        .interpolationMethod(.catmullRom)
                    }

                    if let selectedDate {
                        let matchedExpense = dailyExpenses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
                        let matchedIncome = dailyIncomes.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) })
                        if let refDate = matchedExpense?.date ?? matchedIncome?.date {
                            RuleMark(x: .value("日期", refDate, unit: .day))
                                .foregroundStyle(.secondary.opacity(0.5))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 2]))
                                .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                    VStack(spacing: 4) {
                                        Text(refDate.formatted(.dateTime.month().day().locale(Locale(identifier: "zh-TW"))))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if let e = matchedExpense {
                                            Text("支出 NT$\(String(format: "%.0f", e.total))")
                                                .font(.caption.bold())
                                                .foregroundStyle(AppTheme.expense)
                                        }
                                        if let i = matchedIncome {
                                            Text("收入 NT$\(String(format: "%.0f", i.total))")
                                                .font(.caption.bold())
                                                .foregroundStyle(AppTheme.income)
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                }
                        }
                    }
                }
                .frame(height: 200)
                .chartXSelection(value: $selectedDate)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day().locale(Locale(identifier: "zh-TW")))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartForegroundStyleScale([
                    "支出": AppTheme.expense,
                    "收入": AppTheme.income,
                ])
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

    private var dailyIncomes: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: incomes) { tx in
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
                    .opacity(selectedCategoryName == nil || selectedCategoryName == item.name ? 1.0 : 0.5)
                }
                .frame(height: 200)
                .chartAngleSelection(value: $selectedCategoryAngle)
                .chartBackground { chartProxy in
                    GeometryReader { geometry in
                        if let selectedItem = selectedCategoryItem {
                            let frame = geometry[chartProxy.plotFrame!]
                            VStack(spacing: 2) {
                                Text(selectedItem.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(CurrencyFormatter.format(selectedItem.total))
                                    .font(.callout.bold())
                                    .foregroundStyle(AppTheme.expense)
                                Text(String(format: "%.0f%%", selectedItem.percentage))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .position(x: frame.midX, y: frame.midY)
                        }
                    }
                }

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

    private var selectedCategoryName: String? {
        guard let selectedCategoryAngle else { return nil }
        var cumulative: Double = 0
        let totalDouble = NSDecimalNumber(decimal: totalExpense).doubleValue
        guard totalDouble > 0 else { return nil }
        for item in categoryData {
            let itemAngle = NSDecimalNumber(decimal: item.total).doubleValue / totalDouble
            cumulative += itemAngle
            if selectedCategoryAngle <= cumulative {
                return item.name
            }
        }
        return categoryData.last?.name
    }

    private var selectedCategoryItem: (name: String, colorHex: String, total: Decimal, percentage: Double)? {
        guard let name = selectedCategoryName else { return nil }
        return categoryData.first { $0.name == name }
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
