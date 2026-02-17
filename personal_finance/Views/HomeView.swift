//
//  HomeView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.cardSpacing) {
                    greetingSection
                    MonthlySummaryCard(
                        balance: totalIncome - totalExpense,
                        totalIncome: totalIncome,
                        totalExpense: totalExpense
                    )
                    accountBalanceSection
                    recentTransactionsSection
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
            }
            .background(Color(.secondarySystemBackground))
        }
    }

    private var monthlyTransactions: [Transaction] {
        let calendar = Calendar.current
        let now = Date.now
        guard let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }
        return allTransactions.filter { $0.date >= start && $0.date < end }
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
                Text(Date.now, format: .dateTime.year().month().day().weekday(.wide))
                    .font(AppTheme.captionFont)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            Spacer()
            Image(systemName: "bell")
                .font(.title3)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(.top, 8)
    }

    private var accountBalanceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("帳戶餘額")
                .font(.headline)

            ForEach(Array(accounts.enumerated()), id: \.element.id) { index, account in
                if index > 0 {
                    Divider()
                }
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: account.colorHex).opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: account.icon)
                            .font(.body)
                            .foregroundStyle(Color(hex: account.colorHex))
                    }
                    Text(account.name)
                        .font(.body)
                    Spacer()
                    Text(CurrencyFormatter.format(account.currentBalance))
                        .font(.body.bold().monospacedDigit())
                        .foregroundStyle(account.currentBalance >= 0 ? AppTheme.onBackground : AppTheme.expense)
                }
                .padding(.vertical, 2)
            }
        }
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近交易")
                .font(.headline)

            if monthlyTransactions.isEmpty {
                Text("尚無交易紀錄")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
            } else {
                ForEach(Array(monthlyTransactions.prefix(10).enumerated()), id: \.element.id) { index, tx in
                    if index > 0 {
                        Divider()
                    }
                    TransactionRow(transaction: tx)
                }
            }
        }
    }
}
