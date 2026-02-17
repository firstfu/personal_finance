// ============================================================================
// MARK: - BalanceAdjustmentView.swift
// 模組：Views
//
// 功能說明：
//   餘額調整頁面，以 Sheet 形式呈現。
//   讓使用者輸入實際餘額，自動計算差額並建立調整交易。
//
// 主要職責：
//   - 顯示帳戶目前餘額
//   - 提供實際餘額輸入欄位
//   - 計算並顯示差額
//   - 建立 adjustment 類型的交易以調整餘額
// ============================================================================

import SwiftUI
import SwiftData

struct BalanceAdjustmentView: View {
    let account: Account
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var actualBalanceText = ""
    @State private var note = ""

    private var currentBalance: Decimal {
        account.currentBalance
    }

    private var actualBalance: Decimal? {
        Decimal(string: actualBalanceText)
    }

    private var difference: Decimal? {
        guard let actual = actualBalance else { return nil }
        return actual - currentBalance
    }

    private var canSave: Bool {
        guard let diff = difference else { return false }
        return diff != 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("目前餘額") {
                    Text(CurrencyFormatter.format(currentBalance))
                        .font(.title2.bold())
                        .foregroundStyle(currentBalance >= 0 ? AppTheme.income : AppTheme.expense)
                }

                Section("實際餘額") {
                    TextField("輸入實際餘額", text: $actualBalanceText)
                        .keyboardType(.decimalPad)
                }

                if let diff = difference, diff != 0 {
                    Section("差額") {
                        let prefix = diff > 0 ? "+" : ""
                        Text(prefix + CurrencyFormatter.format(diff))
                            .font(.title3.bold())
                            .foregroundStyle(diff > 0 ? AppTheme.income : AppTheme.expense)
                    }
                }

                Section("備註（選填）") {
                    TextField("例如：忘記記帳的消費", text: $note)
                }
            }
            .navigationTitle("調整餘額")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確認調整") {
                        saveAdjustment()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveAdjustment() {
        guard let diff = difference, diff != 0 else { return }
        let transaction = Transaction(
            amount: diff,
            type: .adjustment,
            account: account,
            note: note.isEmpty ? "餘額調整" : note
        )
        modelContext.insert(transaction)
    }
}
