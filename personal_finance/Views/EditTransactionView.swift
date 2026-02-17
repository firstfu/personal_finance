import SwiftUI
import SwiftData
import UIKit
import WidgetKit

struct EditTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    let transaction: Transaction

    @State private var selectedType: TransactionType
    @State private var amountText: String
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var selectedTransferToAccount: Account?
    @State private var date: Date
    @State private var note: String
    @State private var showDatePicker = false
    @State private var isEditingNote = false
    @FocusState private var isNoteFieldFocused: Bool

    init(transaction: Transaction) {
        self.transaction = transaction
        _selectedType = State(initialValue: transaction.type)
        _amountText = State(initialValue: transaction.amountString == "0" ? "" : transaction.amountString)
        _selectedCategory = State(initialValue: transaction.category)
        _selectedAccount = State(initialValue: transaction.account)
        _selectedTransferToAccount = State(initialValue: transaction.transferToAccount)
        _date = State(initialValue: transaction.date)
        _note = State(initialValue: transaction.note)
    }

    private var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    private var canSave: Bool {
        guard let amount = Decimal(string: amountText), amount > 0 else { return false }
        if selectedType == .transfer {
            return selectedAccount != nil
                && selectedTransferToAccount != nil
                && selectedAccount?.id != selectedTransferToAccount?.id
        }
        return selectedCategory != nil && selectedAccount != nil
    }

    private var dateLabel: String {
        if Calendar.current.isDateInToday(date) {
            return "今天"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    private var typeColor: Color {
        switch selectedType {
        case .expense: AppTheme.expense
        case .income: AppTheme.income
        case .transfer: AppTheme.primary
        }
    }

    private var typeGradient: LinearGradient {
        switch selectedType {
        case .expense:
            LinearGradient(colors: [AppTheme.expense, AppTheme.expense.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .income:
            LinearGradient(colors: [AppTheme.income, AppTheme.income.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .transfer:
            LinearGradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 1. 金額卡片（含類型切換）
                    amountCard
                        .padding(.horizontal, AppTheme.horizontalPadding)
                        .padding(.top, 8)

                    // 2. 詳細資訊
                    detailsSection
                        .padding(.horizontal, AppTheme.horizontalPadding)
                        .padding(.top, 10)

                    Spacer(minLength: 0)

                    // 3. 數字鍵盤
                    NumberPadView(
                        text: $amountText,
                        onSave: updateTransaction,
                        canSave: canSave,
                        saveButtonColor: typeColor
                    )
                    .padding(.bottom, 8)
                }
                .frame(maxWidth: 500)
            }
            .navigationTitle("編輯交易")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
        }
    }

    // MARK: - 金額卡片

    private var amountCard: some View {
        VStack(spacing: 12) {
            // 類型切換
            HStack(spacing: 0) {
                typeTab("支出", type: .expense)
                typeTab("收入", type: .income)
                typeTab("轉帳", type: .transfer)
            }
            .background(Color(.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 20)

            // 金額顯示
            VStack(spacing: 2) {
                Text("NT$")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(amountText.isEmpty ? .white.opacity(0.5) : .white.opacity(0.8))

                Text(NumberPadLogic.formatted(amountText))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.snappy(duration: 0.2), value: amountText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(typeGradient)
                .shadow(color: typeColor.opacity(0.3), radius: 8, y: 4)
        )
        .animation(.easeInOut(duration: 0.25), value: selectedType)
    }

    private func typeTab(_ label: String, type: TransactionType) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedType = type
                if type == .transfer {
                    selectedCategory = nil
                }
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(selectedType == type ? .white : .clear)
                .foregroundStyle(selectedType == type ? typeColor : .white.opacity(0.7))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .padding(2)
    }

    // MARK: - 詳細資訊區

    private var detailsSection: some View {
        VStack(spacing: 10) {
            if selectedType == .transfer {
                // 轉帳：來源帳戶
                transferAccountSelector(
                    title: "從",
                    selection: $selectedAccount,
                    excludeAccount: selectedTransferToAccount
                )

                // 轉帳：目標帳戶
                transferAccountSelector(
                    title: "到",
                    selection: $selectedTransferToAccount,
                    excludeAccount: selectedAccount
                )
            } else {
                // 收入/支出：帳戶選擇
                accountSelector

                // 分類網格
                categoryGrid
            }

            // 日期/備註列
            dateNoteBar
        }
    }

    // MARK: - 帳戶選擇

    private var accountSelector: some View {
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
                                .foregroundStyle(isSelected ? typeColor : AppTheme.secondaryText)
                            Text(account.name)
                                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                .foregroundStyle(isSelected ? AppTheme.onBackground : AppTheme.secondaryText)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? typeColor.opacity(0.12) : AppTheme.surface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? typeColor.opacity(0.4) : .clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 轉帳帳戶選擇

    private func transferAccountSelector(
        title: String,
        selection: Binding<Account?>,
        excludeAccount: Account?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(accounts) { account in
                        let isSelected = selection.wrappedValue?.id == account.id
                        let isExcluded = excludeAccount?.id == account.id
                        Button {
                            selection.wrappedValue = account
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: account.icon)
                                    .font(.caption)
                                    .foregroundStyle(isSelected ? typeColor : AppTheme.secondaryText)
                                Text(account.name)
                                    .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                    .foregroundStyle(isSelected ? AppTheme.onBackground : AppTheme.secondaryText)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? typeColor.opacity(0.12) : AppTheme.surface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? typeColor.opacity(0.4) : .clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.plain)
                        .opacity(isExcluded ? 0.4 : 1.0)
                        .disabled(isExcluded)
                    }
                }
            }
        }
    }

    // MARK: - 分類網格

    private var categoryGrid: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 10) {
                ForEach(filteredCategories) { category in
                    categoryButton(category)
                }
            }
            .padding(.vertical, 4)
        }
        .frame(maxHeight: 170)
    }

    private func categoryButton(_ category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id
        let catColor = Color(hex: category.colorHex)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.15)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(isSelected ? catColor.opacity(0.2) : AppTheme.surface)
                        .frame(width: 52, height: 52)
                    Image(systemName: category.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(catColor)
                }
                .overlay {
                    Circle()
                        .stroke(isSelected ? catColor : .clear, lineWidth: 2)
                        .frame(width: 52, height: 52)
                }
                .scaleEffect(isSelected ? 1.08 : 1.0)

                Text(category.name)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.onBackground : AppTheme.secondaryText)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 日期/備註列

    private var dateNoteBar: some View {
        HStack(spacing: 8) {
            // 日期晶片
            Button {
                showDatePicker = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12))
                    Text(dateLabel)
                        .font(.subheadline)
                }
                .foregroundStyle(AppTheme.onBackground)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.surface)
                )
            }
            .buttonStyle(.plain)

            // 備註
            if isEditingNote {
                TextField("輸入備註...", text: $note)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.surface)
                    )
                    .focused($isNoteFieldFocused)
                    .onAppear { isNoteFieldFocused = true }
                    .onSubmit {
                        isEditingNote = false
                        isNoteFieldFocused = false
                    }
                    .submitLabel(.done)
            } else {
                Button {
                    isEditingNote = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: note.isEmpty ? "square.and.pencil" : "note.text")
                            .font(.system(size: 12))
                        Text(note.isEmpty ? "備註" : note)
                            .font(.subheadline)
                            .lineLimit(1)
                    }
                    .foregroundStyle(note.isEmpty ? AppTheme.secondaryText : AppTheme.onBackground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppTheme.surface)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    // MARK: - 日期選擇器 Sheet

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker("選擇日期", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .navigationTitle("選擇日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") { showDatePicker = false }
                    }
                }
        }
        .presentationDetents([.medium])
    }

    // MARK: - 更新交易

    private func updateTransaction() {
        guard let amount = Decimal(string: amountText), amount > 0 else { return }

        isNoteFieldFocused = false
        isEditingNote = false

        transaction.amountString = "\(amount)"
        transaction.type = selectedType
        transaction.category = selectedType == .transfer ? nil : selectedCategory
        transaction.account = selectedAccount
        transaction.transferToAccount = selectedType == .transfer ? selectedTransferToAccount : nil
        transaction.date = date
        transaction.note = note

        try? modelContext.save()
        WidgetDataSync.updateSnapshot(from: modelContext)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
