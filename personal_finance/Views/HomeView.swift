//
//  HomeView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - HomeView.swift
// 模組：Views
//
// 功能說明：
//   應用程式的首頁主畫面，作為使用者進入 App 後的第一個頁面。
//   提供當月財務總覽、各帳戶餘額及最近交易紀錄的快速瀏覽。
//
// 主要職責：
//   - 顯示問候語及當前日期（繁體中文格式）
//   - 計算並展示當月收入、支出與餘額摘要
//   - 按帳戶類型匯總餘額與總淨值
//   - 顯示最近 5 筆交易紀錄
//
// UI 結構：
//   - greetingSection: 頂部問候區，顯示「嗨，你好」與日期，右側有通知鈴鐺圖示
//   - MonthlySummaryCard: 本月餘額摘要卡片（收入/支出/餘額）
//   - accountBalanceSection: 帳戶總覽卡片，按類型匯總餘額，底部顯示總淨值
//   - recentTransactionsSection: 最近交易卡片，顯示最新 5 筆，使用 TransactionRow 元件呈現
//
// 資料依賴：
//   - @Query allTransactions: 全部交易紀錄，依日期降序排列
//   - @Query accounts: 全部帳戶，依 sortOrder 排序
//
// 注意事項：
//   - monthlyTransactions 為 computed property，每次存取皆重新計算當月交易
//   - 金額計算使用 Decimal 型別確保精度
//   - 帳戶餘額為負數時以紅色（expense 色）顯示
// ============================================================================

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    @AppStorage("showDemoData") private var showDemoData = false
    @State private var periodState = TimePeriodState(periodType: .month)
    @State private var selectedTransaction: Transaction?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    greetingSection
                    monthNavigationBar
                    MonthlySummaryCard(
                        title: periodState.periodLabel + "餘額",
                        balance: totalIncome - totalExpense,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense
                    )
                    accountBalanceSection
                    recentTransactionsSection
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
            }
            .background(AppTheme.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private var monthNavigationBar: some View {
        HStack {
            Button {
                periodState.goBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.body.bold())
                    .foregroundStyle(AppTheme.primary)
                    .frame(width: 36, height: 36)
            }

            Spacer()

            Text(periodState.periodLabel)
                .font(.subheadline.bold())

            Spacer()

            Button {
                periodState.goForward()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.body.bold())
                    .foregroundStyle(periodState.isCurrentPeriod ? AppTheme.secondaryText.opacity(0.3) : AppTheme.primary)
                    .frame(width: 36, height: 36)
            }
            .disabled(periodState.isCurrentPeriod)
        }
    }

    private var activeTransactions: [Transaction] {
        allTransactions.filter { showDemoData ? $0.isDemoData : !$0.isDemoData }
    }

    private var monthlyTransactions: [Transaction] {
        let range = periodState.dateRange
        return activeTransactions.filter { $0.date >= range.start && $0.date < range.end }
    }

    private var totalIncome: Decimal {
        monthlyTransactions.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    private var totalExpense: Decimal {
        monthlyTransactions.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    private var greetingSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("嗨，你好")
                    .font(AppTheme.titleFont)
                    .foregroundStyle(AppTheme.onBackground)
                Text(Self.chineseDateString)
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "bell")
                .font(.title3)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, showDemoData ? 32 : 8)
    }

    private static var chineseDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy 年 M 月 d 日 EEEE"
        return formatter.string(from: .now)
    }

    private var accountBalanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("帳戶總覽")
                    .font(.headline)
                Spacer()
                NavigationLink("查看全部") {
                    AllAccountsView()
                }
                .font(.subheadline)
                .foregroundStyle(AppTheme.primary)
            }

            // 按帳戶類型匯總
            ForEach(AccountType.allCases, id: \.self) { type in
                let typeAccounts = accounts.filter { $0.type == type }
                if !typeAccounts.isEmpty {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Image(systemName: type.defaultIcon)
                                .font(.body)
                                .foregroundStyle(AppTheme.primary)
                        }
                        Text(type.displayName)
                            .font(.body)
                        Spacer()
                        let total = typeAccounts.reduce(Decimal.zero) { $0 + (showDemoData ? $1.demoBalance : $1.currentBalance) }
                        Text(CurrencyFormatter.format(total))
                            .font(.body.bold().monospacedDigit())
                            .foregroundStyle(total >= 0 ? AppTheme.onBackground : AppTheme.expense)
                    }
                    .padding(.vertical, 2)
                }
            }

            Divider()

            // 總淨值
            HStack {
                Text("總淨值")
                    .font(.headline)
                Spacer()
                let totalNetWorth = accounts.reduce(Decimal.zero) { $0 + (showDemoData ? $1.demoBalance : $1.currentBalance) }
                Text(CurrencyFormatter.format(totalNetWorth))
                    .font(.headline.bold().monospacedDigit())
                    .foregroundStyle(totalNetWorth >= 0 ? AppTheme.income : AppTheme.expense)
            }
            .padding(.vertical, 2)
        }
        .padding()
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("最近交易")
                    .font(.headline)
                Spacer()
                NavigationLink("查看全部") {
                    AllTransactionsView()
                }
                .font(.subheadline)
                .foregroundStyle(AppTheme.primary)
            }

            if activeTransactions.isEmpty {
                Text("尚無交易紀錄")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(Array(activeTransactions.prefix(5).enumerated()), id: \.element.id) { index, tx in
                    if index > 0 {
                        Divider()
                    }
                    TransactionRow(transaction: tx)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedTransaction = tx
                        }
                }
            }
        }
        .padding()
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .sheet(item: $selectedTransaction) { tx in
            EditTransactionView(transaction: tx)
        }
    }
}
