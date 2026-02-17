//
//  AllAccountsView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI
import SwiftData

struct AllAccountsView: View {
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    var body: some View {
        List {
            ForEach(AccountType.allCases, id: \.self) { type in
                let typeAccounts = accounts.filter { $0.type == type }
                if !typeAccounts.isEmpty {
                    Section(header: Text(type.displayName)) {
                        ForEach(typeAccounts) { account in
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
                            .padding(.vertical, 4)
                        }
                    }
                }
            }

            Section {
                HStack {
                    Text("總淨值")
                        .font(.headline)
                    Spacer()
                    let totalNetWorth = accounts.reduce(Decimal.zero) { $0 + $1.currentBalance }
                    Text(CurrencyFormatter.format(totalNetWorth))
                        .font(.headline.bold().monospacedDigit())
                        .foregroundStyle(totalNetWorth >= 0 ? AppTheme.income : AppTheme.expense)
                }
            }
        }
        .navigationTitle("帳戶總覽")
        .navigationBarTitleDisplayMode(.large)
    }
}
