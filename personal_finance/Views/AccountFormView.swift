// ============================================================================
// MARK: - AccountFormView.swift
// 模組：Views
//
// 功能說明：
//   帳戶新增與編輯表單頁面，以 Sheet 形式呈現。
//   提供帳戶名稱、類型、初始餘額與顏色的設定，支援新增與編輯兩種模式。
//
// 主要職責：
//   - 提供帳戶名稱輸入欄位
//   - 提供帳戶類型選擇（bank/cash/credit 等，透過 AccountType enum）
//   - 切換帳戶類型時自動更新對應的預設圖標
//   - 提供初始餘額輸入欄位（僅數字鍵盤）
//   - 以 6 欄網格顯示 12 個預設顏色供選取
//   - 新增模式：建立新 Account 物件並插入 ModelContext
//   - 編輯模式：載入現有帳戶資料並就地更新屬性
//
// UI 結構：
//   - Form 表單:
//     - TextField: 帳戶名稱輸入
//     - Picker: 帳戶類型選擇（遍歷 AccountType.allCases）
//     - Section「初始餘額」: 數字輸入欄位
//     - Section「顏色」: LazyVGrid 顏色選擇網格
//   - Toolbar:
//     - 取消按鈕（cancellationAction）
//     - 儲存按鈕（confirmationAction），名稱為空時禁用
//
// 資料依賴：
//   - @Environment(\.modelContext): 用於插入新帳戶
//   - @Environment(\.dismiss): 關閉 Sheet
//   - Mode enum: .add（新增）或 .edit(Account)（編輯）
//   - @State name / type / icon / colorHex / initialBalance: 表單狀態
//
// 注意事項：
//   - Mode 遵循 Identifiable 協定以支援 .sheet(item:) 綁定
//   - 編輯模式下 onAppear 時從既有帳戶載入初始值
//   - 帳戶圖標由 type.defaultIcon 自動決定，非使用者手動選取
//   - 新增模式下 sortOrder 預設為 99（排序至最後）
//   - 初始餘額使用 Decimal(string:) 解析，解析失敗時預設為 0
// ============================================================================

import SwiftUI
import SwiftData

struct AccountFormView: View {
    enum Mode: Identifiable {
        case add
        case edit(Account)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let acc): return "\(acc.persistentModelID.hashValue)"
            }
        }
    }

    let mode: Mode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var type: AccountType = .bank
    @State private var icon = "building.columns.fill"
    @State private var colorHex = "#2196F3"
    @State private var initialBalance = ""
    @State private var showBalanceAdjustment = false

    private let colorOptions = [
        "#4CAF50", "#2196F3", "#FF9800", "#E91E63",
        "#9C27B0", "#00BCD4", "#795548", "#607D8B",
        "#F44336", "#FFC107", "#3F51B5", "#8BC34A"
    ]

    var body: some View {
        NavigationStack {
            Form {
                TextField("名稱", text: $name)

                Picker("類型", selection: $type) {
                    ForEach(AccountType.allCases, id: \.self) { t in
                        Text(t.displayName).tag(t)
                    }
                }
                .onChange(of: type) {
                    icon = type.defaultIcon
                }

                Section("初始餘額") {
                    TextField("0", text: $initialBalance)
                        .keyboardType(.numberPad)
                }

                if case .edit(let account) = mode {
                    Section("目前餘額") {
                        HStack {
                            Text(CurrencyFormatter.format(account.currentBalance))
                                .font(.title3.bold())
                                .foregroundStyle(account.currentBalance >= 0 ? AppTheme.income : AppTheme.expense)
                            Spacer()
                            Button("調整餘額") {
                                showBalanceAdjustment = true
                            }
                            .font(.callout)
                        }
                    }
                }

                Section("顏色") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(colorOptions, id: \.self) { hex in
                            Button {
                                colorHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 32, height: 32)
                                    .overlay {
                                        if colorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "編輯帳戶" : "新增帳戶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if case .edit(let account) = mode {
                    name = account.name
                    type = account.type
                    icon = account.icon
                    colorHex = account.colorHex
                    initialBalance = "\(account.initialBalance)"
                }
            }
            .sheet(isPresented: $showBalanceAdjustment) {
                if case .edit(let account) = mode {
                    BalanceAdjustmentView(account: account)
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func save() {
        let balance = Decimal(string: initialBalance) ?? 0
        switch mode {
        case .add:
            let account = Account(
                name: name,
                type: type,
                icon: type.defaultIcon,
                colorHex: colorHex,
                initialBalance: balance,
                sortOrder: 99
            )
            modelContext.insert(account)
        case .edit(let account):
            account.name = name
            account.type = type
            account.icon = type.defaultIcon
            account.colorHex = colorHex
            account.initialBalance = balance
        }
    }
}
