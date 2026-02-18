//
//  AnalyticsView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - AnalyticsView.swift
// 模組：Views
//
// 功能說明：
//   財務分析頁面，提供使用者視覺化的收支趨勢分析與分類佔比圖表。
//   支援本週、本月、本年三種時間區間切換，透過折線圖與圓餅圖
//   呈現財務資料的多維度分析。
//
// 主要職責：
//   - 依選定期間篩選交易，計算總收入、總支出與淨額
//   - 繪製收支累計趨勢折線圖（支援支出/收入/淨額三條線的開關切換）
//   - 繪製支出分類與收入分類的互動式圓餅圖
//   - 提供圖表互動功能（點選日期顯示詳細數據、點選扇形區顯示分類明細）
//
// UI 結構：
//   - periodPicker: 期間選擇器（本週/本月/本年），使用 Segmented 樣式
//   - spendingSummaryCard: 總支出、總收入與淨額摘要卡片
//   - expenseTrendChart: 收支趨勢折線圖，含面積填充與互動選取標記
//   - trendLineFilter: 趨勢圖篩選膠囊按鈕（支出/收入/淨額開關）
//   - categoryBreakdown: 分類佔比區，包含支出圓餅圖與收入圓餅圖
//   - pieChart(): 可複用的圓餅圖元件，支援中心顯示選取項目詳情
//
// 資料依賴：
//   - @Query allTransactions: 全部交易紀錄，依日期降序排列
//   - @State selectedPeriod: 當前選取的時間區間
//   - @State selectedDate: 趨勢圖中選取的日期（用於 RuleMark 標記）
//   - @State selectedCategoryAngle / selectedIncomeCategoryAngle: 圓餅圖選取角度
//   - @State showExpenseLine / showIncomeLine / showAssetLine: 趨勢線顯示開關
//
// 注意事項：
//   - 趨勢圖資料為累計值（dailyExpenses/dailyIncomes/dailyAsset），非單日金額
//   - 金額在 Charts 渲染時透過 NSDecimalNumber 轉換為 Double
//   - 至少須保留一條趨勢線處於開啟狀態（toggleLine 邏輯控制）
//   - 圓餅圖使用 chartAngleSelection 實現互動，透過角度累計定位選取項
// ============================================================================

import SwiftUI
import SwiftData
import Charts

struct AnalyticsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    @AppStorage("showDemoData") private var showDemoData = false
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    @State private var periodState = TimePeriodState()
    @State private var selectedDate: Date?
    @State private var selectedCategoryAngle: Double?
    @State private var selectedIncomeCategoryAngle: Double?
    @State private var showExpenseLine: Bool = true
    @State private var showIncomeLine: Bool = true
    @State private var showAssetLine: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    PeriodNavigationBar(state: $periodState)
                    spendingSummaryCard
                    expenseTrendChart
                    categoryBreakdown
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
            }
            .navigationTitle("分析")
            .navigationBarTitleDisplayMode(.large)
            .background(AppTheme.background)
        }
    }

    private var activeTransactions: [Transaction] {
        allTransactions.filter { showDemoData ? $0.isDemoData : !$0.isDemoData }
    }

    private var filteredTransactions: [Transaction] {
        let range = periodState.dateRange
        return activeTransactions.filter { $0.date >= range.start && $0.date < range.end }
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

    private var totalBalance: Decimal {
        accounts.reduce(Decimal.zero) { $0 + (showDemoData ? $1.demoBalance : $1.currentBalance) }
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

            Divider()

            VStack(spacing: 4) {
                Text("總資產")
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
                Text(CurrencyFormatter.format(totalBalance))
                    .font(AppTheme.amountFont)
                    .foregroundStyle(totalBalance >= 0 ? AppTheme.income : AppTheme.expense)
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

            trendLineFilter

            if expenses.isEmpty && incomes.isEmpty {
                Text("尚無資料")
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, minHeight: 200)
            } else {
                Chart {
                    if showExpenseLine {
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
                    }

                    if showIncomeLine {
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
                    }

                    if showAssetLine {
                        ForEach(dailyAsset, id: \.date) { data in
                            LineMark(
                                x: .value("日期", data.date, unit: .day),
                                y: .value("金額", data.total),
                                series: .value("類型", "總資產")
                            )
                            .foregroundStyle(AppTheme.primary)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2, dash: [6, 3]))
                        }
                    }

                    if let selectedDate {
                        let matchedExpense = showExpenseLine ? dailyExpenses.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) : nil
                        let matchedIncome = showIncomeLine ? dailyIncomes.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) : nil
                        let matchedAsset = showAssetLine ? dailyAsset.first(where: { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }) : nil
                        if let refDate = matchedExpense?.date ?? matchedIncome?.date ?? matchedAsset?.date {
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
                                        if let a = matchedAsset {
                                            Text("總資產 NT$\(String(format: "%.0f", a.total))")
                                                .font(.caption.bold())
                                                .foregroundStyle(AppTheme.primary)
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
                .chartForegroundStyleScale(domain: activeTrendDomain, range: activeTrendRange)
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var activeLineCount: Int {
        [showExpenseLine, showIncomeLine, showAssetLine].filter { $0 }.count
    }

    private func toggleLine(_ line: inout Bool) {
        if line && activeLineCount <= 1 { return }
        line.toggle()
    }

    private var trendLineFilter: some View {
        HStack(spacing: 8) {
            trendFilterChip(label: "支出", color: AppTheme.expense, isOn: $showExpenseLine)
            trendFilterChip(label: "收入", color: AppTheme.income, isOn: $showIncomeLine)
            trendFilterChip(label: "總資產", color: AppTheme.primary, isOn: $showAssetLine)
        }
    }

    private func trendFilterChip(label: String, color: Color, isOn: Binding<Bool>) -> some View {
        Button {
            toggleLine(&isOn.wrappedValue)
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(label)
                    .font(.caption)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isOn.wrappedValue ? color.opacity(0.15) : Color.clear)
            .foregroundStyle(isOn.wrappedValue ? color : .secondary)
            .overlay(
                Capsule()
                    .stroke(isOn.wrappedValue ? color : Color.secondary.opacity(0.3), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var activeTrendDomain: [String] {
        var result: [String] = []
        if showExpenseLine { result.append("支出") }
        if showIncomeLine { result.append("收入") }
        if showAssetLine { result.append("總資產") }
        return result
    }

    private var activeTrendRange: [Color] {
        var result: [Color] = []
        if showExpenseLine { result.append(AppTheme.expense) }
        if showIncomeLine { result.append(AppTheme.income) }
        if showAssetLine { result.append(AppTheme.primary) }
        return result
    }

    private var dailyExpenses: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expenses) { tx in
            calendar.startOfDay(for: tx.date)
        }
        let daily = grouped.map { (date: $0.key, total: NSDecimalNumber(decimal: $0.value.reduce(0) { $0 + $1.amount }).doubleValue) }
            .sorted { $0.date < $1.date }
        var cumulative: Double = 0
        return daily.map { item in
            cumulative += item.total
            return (date: item.date, total: cumulative)
        }
    }

    private var dailyIncomes: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: incomes) { tx in
            calendar.startOfDay(for: tx.date)
        }
        let daily = grouped.map { (date: $0.key, total: NSDecimalNumber(decimal: $0.value.reduce(0) { $0 + $1.amount }).doubleValue) }
            .sorted { $0.date < $1.date }
        var cumulative: Double = 0
        return daily.map { item in
            cumulative += item.total
            return (date: item.date, total: cumulative)
        }
    }

    private var baseBalance: Double {
        let total = accounts.reduce(Decimal.zero) { $0 + $1.initialBalance }
        return NSDecimalNumber(decimal: total).doubleValue
    }

    private var dailyAsset: [(date: Date, total: Double)] {
        let calendar = Calendar.current
        let allDates = Set(
            (expenses + incomes).map { calendar.startOfDay(for: $0.date) }
        )
        let expenseByDay = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
        let incomeByDay = Dictionary(grouping: incomes) { calendar.startOfDay(for: $0.date) }
        let daily = allDates.map { date in
            let inc = incomeByDay[date]?.reduce(Decimal.zero) { $0 + $1.amount } ?? .zero
            let exp = expenseByDay[date]?.reduce(Decimal.zero) { $0 + $1.amount } ?? .zero
            return (date: date, total: NSDecimalNumber(decimal: inc - exp).doubleValue)
        }
        .sorted { $0.date < $1.date }
        var cumulative: Double = baseBalance
        return daily.map { item in
            cumulative += item.total
            return (date: item.date, total: cumulative)
        }
    }

    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            pieChart(
                title: "支出分類",
                data: categoryData,
                selectedAngle: $selectedCategoryAngle,
                accentColor: AppTheme.expense
            )

            if !incomes.isEmpty {
                Divider()
                    .padding(.vertical, 4)

                pieChart(
                    title: "收入分類",
                    data: incomeCategoryData,
                    selectedAngle: $selectedIncomeCategoryAngle,
                    accentColor: AppTheme.income
                )
            }
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    @ViewBuilder
    private func pieChart(
        title: String,
        data: [(name: String, colorHex: String, total: Decimal, percentage: Double)],
        selectedAngle: Binding<Double?>,
        accentColor: Color
    ) -> some View {
        Text(title)
            .font(.headline)

        if data.isEmpty {
            Text("尚無資料")
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        } else {
            let selectedName = findSelectedName(in: data, angle: selectedAngle.wrappedValue)
            let selectedItem = data.first { $0.name == selectedName }

            Chart(data, id: \.name) { item in
                SectorMark(
                    angle: .value("金額", NSDecimalNumber(decimal: item.total).doubleValue),
                    innerRadius: .ratio(0.5),
                    angularInset: 1
                )
                .foregroundStyle(Color(hex: item.colorHex))
                .opacity(selectedName == nil || selectedName == item.name ? 1.0 : 0.5)
            }
            .frame(height: 200)
            .chartAngleSelection(value: selectedAngle)
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let selectedItem {
                        let frame = geometry[chartProxy.plotFrame!]
                        VStack(spacing: 2) {
                            Text(selectedItem.name)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.format(selectedItem.total))
                                .font(.callout.bold())
                                .foregroundStyle(accentColor)
                            Text(String(format: "%.0f%%", selectedItem.percentage))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }

            ForEach(data, id: \.name) { item in
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

    private func findSelectedName(
        in data: [(name: String, colorHex: String, total: Decimal, percentage: Double)],
        angle: Double?
    ) -> String? {
        guard let angle else { return nil }
        var cumulative: Double = 0
        for item in data {
            cumulative += NSDecimalNumber(decimal: item.total).doubleValue
            if angle <= cumulative {
                return item.name
            }
        }
        return data.last?.name
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

    private var incomeCategoryData: [(name: String, colorHex: String, total: Decimal, percentage: Double)] {
        let grouped = Dictionary(grouping: incomes) { $0.category?.name ?? "未分類" }
        let total = totalIncome
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
