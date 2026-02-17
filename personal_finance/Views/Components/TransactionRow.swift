//
//  TransactionRow.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.category?.icon ?? "questionmark.circle")
                    .foregroundStyle(categoryColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category?.name ?? "未分類")
                    .font(.body)
                    .foregroundStyle(AppTheme.onBackground)
                if !transaction.note.isEmpty {
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
                    .foregroundStyle(transaction.type == .income ? AppTheme.income : AppTheme.expense)
                Text(transaction.date, format: .dateTime.month().day().locale(Locale(identifier: "zh-TW")))
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                if let accountName = transaction.account?.name {
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

    private var amountText: String {
        let prefix = transaction.type == .income ? "+" : "-"
        return prefix + CurrencyFormatter.format(transaction.amount)
    }
}
