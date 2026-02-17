// ============================================================================
// MARK: - AddTransactionView.swift
// 模組：Views
//
// 功能說明：
//   新增交易（記帳）頁面，提供使用者輸入收入或支出交易的完整表單。
//   支援選擇交易類型、帳戶、金額輸入、分類選取、日期與備註，
//   儲存後顯示成功動畫回饋。
//
// 主要職責：
//   - 提供支出/收入類型切換
//   - 顯示帳戶選擇器（水平捲動膠囊按鈕），預設選取 isDefault 帳戶
//   - 提供大字體金額輸入欄位（僅數字鍵盤）
//   - 以 4 欄網格顯示分類選擇按鈕（依交易類型篩選）
//   - 儲存交易至 SwiftData 並同步 Widget 資料快照
//   - 儲存成功後重置表單並顯示「已儲存」覆蓋動畫
//
// UI 結構：
//   - Picker（Segmented）: 支出/收入類型切換
//   - accountSelector: 水平捲動的帳戶膠囊按鈕列
//   - amountSection: 大字體金額輸入區，顏色隨交易類型變化
//   - categoryGrid: 4 欄 LazyVGrid 分類圖示按鈕，選取時顯示外框
//   - DatePicker: 日期選擇器（compact 樣式）
//   - TextField: 備註輸入欄位（選填）
//   - saveButton: 儲存按鈕，未填完必要欄位時禁用
//   - savedOverlay: 儲存成功覆蓋層，含打勾圖示與「已儲存」文字
//
// 資料依賴：
//   - @Environment(\.modelContext): 用於寫入交易資料
//   - @Query categories: 全部分類，依 sortOrder 排序
//   - @Query accounts: 全部帳戶，依 sortOrder 排序
//   - @State selectedType / amountText / selectedCategory / selectedAccount / date / note
//
// 注意事項：
//   - 切換交易類型時會清除已選分類（onChange）
//   - canSave 驗證：金額 > 0 且已選分類與帳戶
//   - 儲存後透過 WidgetDataSync.updateSnapshot 同步 Widget
//   - 成功回饋動畫 1.5 秒後自動消失
// ============================================================================

import SwiftUI
import SwiftData
import WidgetKit

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    @State private var selectedType: TransactionType = .expense
    @State private var amountText = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var date = Date.now
    @State private var note = ""
    @State private var showSavedFeedback = false

    private var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Picker("類型", selection: $selectedType) {
                            Text("支出").tag(TransactionType.expense)
                            Text("收入").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedType) {
                            selectedCategory = nil
                        }

                        accountSelector
                        amountSection
                        categoryGrid

                        DatePicker("日期", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .padding(.horizontal, 4)

                        TextField("備註（選填）", text: $note)
                            .textFieldStyle(.roundedBorder)

                        saveButton
                    }
                    .padding(.horizontal, AppTheme.horizontalPadding)
                    .padding(.top, 8)
                }
                .navigationTitle("記帳")
            }

            if showSavedFeedback {
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                    .transition(.opacity)
                savedOverlay
            }
        }
        .animation(.easeInOut, value: showSavedFeedback)
        .onAppear {
            if selectedAccount == nil {
                selectedAccount = accounts.first(where: { $0.isDefault }) ?? accounts.first
            }
        }
    }

    private var accountSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("帳戶")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(accounts) { account in
                        let isSelected = selectedAccount?.id == account.id
                        Button {
                            selectedAccount = account
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: account.icon)
                                    .font(.caption)
                                Text(account.name)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? AppTheme.primaryDark : AppTheme.surface)
                            .foregroundStyle(isSelected ? .white : AppTheme.onBackground)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var amountSection: some View {
        VStack(spacing: 8) {
            Text(selectedType == .expense ? "支出金額" : "收入金額")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            TextField("0", text: $amountText)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .keyboardType(.numberPad)
                .foregroundStyle(selectedType == .expense ? AppTheme.expense : AppTheme.income)
        }
        .padding(.vertical, 16)
    }

    private var categoryGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
            ForEach(filteredCategories) { category in
                categoryButton(category)
            }
        }
    }

    private func categoryButton(_ category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id
        return Button {
            selectedCategory = category
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex).opacity(isSelected ? 0.3 : 0.1))
                        .frame(width: 50, height: 50)
                    Image(systemName: category.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: category.colorHex))
                }
                .overlay {
                    if isSelected {
                        Circle()
                            .stroke(Color(hex: category.colorHex), lineWidth: 2)
                            .frame(width: 50, height: 50)
                    }
                }
                Text(category.name)
                    .font(.caption)
                    .foregroundStyle(AppTheme.onBackground)
            }
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button {
            saveTransaction()
        } label: {
            Text("儲存")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canSave ? AppTheme.primaryDark : Color.gray.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
        }
        .disabled(!canSave)
        .padding(.top, 8)
    }

    private var canSave: Bool {
        guard let amount = Decimal(string: amountText), amount > 0 else { return false }
        return selectedCategory != nil && selectedAccount != nil
    }

    private func saveTransaction() {
        guard let amount = Decimal(string: amountText), amount > 0 else { return }
        let transaction = Transaction(
            amount: amount,
            type: selectedType,
            category: selectedCategory,
            account: selectedAccount,
            note: note,
            date: date
        )
        modelContext.insert(transaction)
        try? modelContext.save()
        WidgetDataSync.updateSnapshot(from: modelContext)

        amountText = ""
        selectedCategory = nil
        note = ""
        date = .now

        withAnimation {
            showSavedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSavedFeedback = false
            }
        }
    }

    private var savedOverlay: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.income)
            Text("已儲存")
                .font(.headline)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .transition(.scale.combined(with: .opacity))
    }
}
