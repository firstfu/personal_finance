import SwiftUI
import SwiftData
import UIKit
import WidgetKit

struct AddTransactionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    @State private var selectedType: TransactionType = .expense
    @State private var amountText = ""
    @State private var selectedCategory: Category?
    @State private var selectedAccount: Account?
    @State private var selectedTransferToAccount: Account?
    @State private var date = Date.now
    @State private var note = ""
    @State private var showSavedFeedback = false
    @State private var showDatePicker = false
    @State private var showAmountPad = false
    @State private var showCategoryPicker = false
    @State private var showAccountPicker = false
    @State private var showTransferToAccountPicker = false
    @FocusState private var isNoteFieldFocused: Bool

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

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "yyyy年M月d日 EEEE"
        return formatter.string(from: date)
    }

    private var typeColor: Color {
        switch selectedType {
        case .expense: AppTheme.expense
        case .income: AppTheme.income
        case .transfer: AppTheme.primary
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 1. 分段控制器
                    segmentedControl
                        .padding(.horizontal, AppTheme.horizontalPadding)
                        .padding(.top, 12)

                    // 2. 日期顯示
                    dateRow
                        .padding(.top, 16)

                    // 3. 表單區域
                    formSection
                        .padding(.horizontal, AppTheme.horizontalPadding)
                        .padding(.top, 16)

                    // 4. 備註
                    noteSection
                        .padding(.horizontal, AppTheme.horizontalPadding)
                        .padding(.top, 12)

                    Spacer()

                    // 5. 底部按鈕
                    bottomButtons
                        .padding(.horizontal, AppTheme.horizontalPadding)
                        .padding(.bottom, 16)
                }
                .frame(maxWidth: 500)

                if showSavedFeedback {
                    Color.black.opacity(0.25)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    savedOverlay
                }
            }
            .navigationTitle("記帳")
            .navigationBarTitleDisplayMode(.large)
            .animation(.easeInOut(duration: 0.3), value: showSavedFeedback)
            .onAppear {
                if selectedAccount == nil {
                    selectedAccount = accounts.first(where: { $0.isDefault }) ?? accounts.first
                }
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $showAmountPad) {
                amountInputSheet
            }
            .sheet(isPresented: $showCategoryPicker) {
                categoryPickerSheet
            }
            .sheet(isPresented: $showAccountPicker) {
                accountPickerSheet(isTransferTo: false)
            }
            .sheet(isPresented: $showTransferToAccountPicker) {
                accountPickerSheet(isTransferTo: true)
            }
        }
    }

    // MARK: - 分段控制器

    private var segmentedControl: some View {
        Picker("交易類型", selection: $selectedType) {
            Text("支出").tag(TransactionType.expense)
            Text("收入").tag(TransactionType.income)
            Text("轉帳").tag(TransactionType.transfer)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedType) {
            selectedCategory = nil
        }
    }

    // MARK: - 日期顯示

    private var dateRow: some View {
        Button {
            showDatePicker = true
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(typeColor)
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.onBackground)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 表單區域

    private var formSection: some View {
        VStack(spacing: 0) {
            // 金額行
            formRow(icon: "yensign.circle.fill", iconColor: typeColor, label: "金額") {
                showAmountPad = true
            } trailing: {
                Text(amountText.isEmpty ? "輸入金額" : "NT$ \(NumberPadLogic.formatted(amountText))")
                    .foregroundStyle(amountText.isEmpty ? AppTheme.secondaryText : AppTheme.onBackground)
            }

            Divider().padding(.leading, 52)

            // 類別行（轉帳模式不顯示）
            if selectedType != .transfer {
                formRow(icon: "square.grid.2x2.fill", iconColor: .orange, label: "類別") {
                    showCategoryPicker = true
                } trailing: {
                    Text(selectedCategory?.name ?? "選擇類別")
                        .foregroundStyle(selectedCategory == nil ? AppTheme.secondaryText : AppTheme.onBackground)
                }

                Divider().padding(.leading, 52)
            }

            // 帳戶行
            formRow(icon: "creditcard.fill", iconColor: .blue, label: selectedType == .transfer ? "轉出帳戶" : "帳戶") {
                showAccountPicker = true
            } trailing: {
                Text(selectedAccount?.name ?? "選擇帳戶")
                    .foregroundStyle(selectedAccount == nil ? AppTheme.secondaryText : AppTheme.onBackground)
            }

            // 轉帳模式：轉入帳戶行
            if selectedType == .transfer {
                Divider().padding(.leading, 52)

                formRow(icon: "arrow.right.circle.fill", iconColor: .green, label: "轉入帳戶") {
                    showTransferToAccountPicker = true
                } trailing: {
                    Text(selectedTransferToAccount?.name ?? "選擇帳戶")
                        .foregroundStyle(selectedTransferToAccount == nil ? AppTheme.secondaryText : AppTheme.onBackground)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func formRow(
        icon: String,
        iconColor: Color,
        label: String,
        action: @escaping () -> Void,
        @ViewBuilder trailing: () -> some View
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
                    .frame(width: 28)

                Text(label)
                    .font(.body)
                    .foregroundStyle(AppTheme.onBackground)

                Spacer()

                trailing()
                    .font(.body)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
        }
        .buttonStyle(.plain)
    }

    // MARK: - 備註區域

    private var noteSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 20))
                .foregroundStyle(.gray)
                .frame(width: 28)

            TextField("寫點備註吧...", text: $note)
                .font(.body)
                .focused($isNoteFieldFocused)
        }
        .padding(.horizontal, 16)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - 底部按鈕

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            // 儲存按鈕（描邊樣式）
            Button(action: {
                saveTransaction(resetAfter: false)
            }) {
                Text("儲存")
                    .font(.headline)
                    .foregroundStyle(canSave ? typeColor : AppTheme.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                            .stroke(canSave ? typeColor : AppTheme.secondaryText.opacity(0.3), lineWidth: 2)
                    )
            }
            .disabled(!canSave)

            // 再記一筆按鈕（填色樣式）
            Button(action: {
                saveTransaction(resetAfter: true)
            }) {
                Text("再記一筆")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                            .fill(canSave ? typeColor : Color.gray.opacity(0.3))
                    )
            }
            .disabled(!canSave)
        }
    }

    // MARK: - 金額輸入 Sheet

    private var amountInputSheet: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Spacer()

                // 金額顯示
                VStack(spacing: 4) {
                    Text("NT$")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(NumberPadLogic.formatted(amountText))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.onBackground)
                        .contentTransition(.numericText())
                        .animation(.snappy(duration: 0.2), value: amountText)
                }
                .padding(.bottom, 24)

                // 數字鍵盤
                NumberPadView(
                    text: $amountText,
                    onSave: { showAmountPad = false },
                    canSave: !amountText.isEmpty && amountText != "0",
                    saveButtonColor: typeColor,
                    saveButtonLabel: "確認"
                )
                .padding(.bottom, 8)
            }
            .navigationTitle("輸入金額")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showAmountPad = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - 類別選擇 Sheet

    private var categoryPickerSheet: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 4), spacing: 16) {
                    ForEach(filteredCategories) { category in
                        categoryButton(category)
                    }
                }
                .padding()
            }
            .navigationTitle("選擇類別")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { showCategoryPicker = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func categoryButton(_ category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id
        let catColor = Color(hex: category.colorHex)
        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            selectedCategory = category
            showCategoryPicker = false
        } label: {
            VStack(spacing: 6) {
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

                Text(category.name)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.onBackground : AppTheme.secondaryText)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 帳戶選擇 Sheet

    private func accountPickerSheet(isTransferTo: Bool) -> some View {
        NavigationStack {
            List(accounts) { account in
                let isSelected = isTransferTo
                    ? selectedTransferToAccount?.id == account.id
                    : selectedAccount?.id == account.id
                let isDisabled = isTransferTo && selectedAccount?.id == account.id

                Button {
                    if isTransferTo {
                        selectedTransferToAccount = account
                        showTransferToAccountPicker = false
                    } else {
                        selectedAccount = account
                        if selectedTransferToAccount?.id == account.id {
                            selectedTransferToAccount = nil
                        }
                        showAccountPicker = false
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: account.icon)
                            .font(.system(size: 18))
                            .foregroundStyle(Color(hex: account.colorHex))
                            .frame(width: 28)

                        Text(account.name)
                            .font(.body)
                            .foregroundStyle(isDisabled ? AppTheme.secondaryText : AppTheme.onBackground)

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark")
                                .font(.body.bold())
                                .foregroundStyle(typeColor)
                        }
                    }
                }
                .disabled(isDisabled)
                .listRowBackground(isSelected ? typeColor.opacity(0.08) : Color.clear)
            }
            .navigationTitle(isTransferTo ? "轉入帳戶" : "選擇帳戶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if isTransferTo {
                            showTransferToAccountPicker = false
                        } else {
                            showAccountPicker = false
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
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

    // MARK: - 儲存

    private func saveTransaction(resetAfter: Bool) {
        guard let amount = Decimal(string: amountText), amount > 0 else { return }

        isNoteFieldFocused = false

        let transaction = Transaction(
            amount: amount,
            type: selectedType,
            category: selectedType == .transfer ? nil : selectedCategory,
            account: selectedAccount,
            transferToAccount: selectedType == .transfer ? selectedTransferToAccount : nil,
            note: note,
            date: date
        )
        modelContext.insert(transaction)
        try? modelContext.save()
        WidgetDataSync.updateSnapshot(from: modelContext)

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        // 重置表單
        amountText = ""
        selectedCategory = nil
        selectedTransferToAccount = nil
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

    // MARK: - 儲存成功動畫

    private var savedOverlay: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.income)
            Text("已儲存")
                .font(.headline)
                .foregroundStyle(AppTheme.onBackground)
        }
        .padding(36)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
        .transition(.scale.combined(with: .opacity))
    }
}
