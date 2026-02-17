//
//  MonthlySummaryCard.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI

struct MonthlySummaryCard: View {
    let balance: Decimal
    let totalIncome: Decimal
    let totalExpense: Decimal

    var body: some View {
        VStack(spacing: 16) {
            Text("本月餘額")
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
