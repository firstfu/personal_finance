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
    @State private var showDatePicker = false
    @State private var isEditingNote = false

    private var filteredCategories: [Category] {
        categories.filter { $0.type == selectedType }
    }

    private var canSave: Bool {
        guard let amount = Decimal(string: amountText), amount > 0 else { return false }
        return selectedCategory != nil && selectedAccount != nil
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // === Upper section ===
                VStack(spacing: 12) {
                    typePicker
                    categoryScrollRow
                    accountChips
                    amountDisplay
                    dateNoteRow
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.top, 8)

                Spacer(minLength: 8)

                // === Lower section: Number pad ===
                NumberPadView(
                    text: $amountText,
                    onSave: saveTransaction,
                    canSave: canSave
                )
                .padding(.bottom, 8)
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
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
    }

    // MARK: - Type Picker

    private var typePicker: some View {
        Picker("類型", selection: $selectedType) {
            Text("支出").tag(TransactionType.expense)
            Text("收入").tag(TransactionType.income)
        }
        .pickerStyle(.segmented)
        .onChange(of: selectedType) {
            selectedCategory = nil
        }
    }

    // MARK: - Category Scroll Row

    private var categoryScrollRow: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(filteredCategories) { category in
                        categoryItem(category)
                            .id(category.id)
                    }
                }
                .padding(.horizontal, 4)
            }
            .onChange(of: selectedType) {
                if let first = filteredCategories.first {
                    withAnimation {
                        proxy.scrollTo(first.id, anchor: .leading)
                    }
                }
            }
        }
    }

    private func categoryItem(_ category: Category) -> some View {
        let isSelected = selectedCategory?.id == category.id
        let color = Color(hex: category.colorHex)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isSelected ? 0.25 : 0.12))
                        .frame(width: 48, height: 48)
                    Image(systemName: category.icon)
                        .font(.system(size: isSelected ? 28 : 22))
                        .foregroundStyle(color)
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)

                Text(category.name)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.onBackground)

                RoundedRectangle(cornerRadius: 1.5)
                    .fill(isSelected ? color : .clear)
                    .frame(width: 24, height: 3)
            }
            .frame(width: 70)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    // MARK: - Account Chips

    private var accountChips: some View {
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
            Spacer()
        }
    }

    // MARK: - Amount Display

    private var amountDisplay: some View {
        VStack(spacing: 4) {
            Text(selectedType == .expense ? "支出金額" : "收入金額")
                .font(AppTheme.captionFont)
                .foregroundStyle(AppTheme.secondaryText)

            Text("NT$ \(NumberPadLogic.formatted(amountText))")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(
                    amountText.isEmpty
                        ? AppTheme.secondaryText
                        : (selectedType == .expense ? AppTheme.expense : AppTheme.income)
                )
                .contentTransition(.numericText())
                .animation(.snappy, value: amountText)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Date + Note Row

    private var dateNoteRow: some View {
        HStack(spacing: 12) {
            Button {
                showDatePicker = true
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption)
                    Text(dateDisplayText)
                        .font(.subheadline)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)

            if isEditingNote {
                TextField("備註", text: $note, onCommit: {
                    isEditingNote = false
                })
                .textFieldStyle(.roundedBorder)
                .font(.subheadline)
            } else {
                Button {
                    isEditingNote = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                            .font(.caption)
                        Text(note.isEmpty ? "新增備註" : note)
                            .font(.subheadline)
                            .foregroundStyle(note.isEmpty ? AppTheme.secondaryText : AppTheme.onBackground)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
    }

    private var dateDisplayText: String {
        if Calendar.current.isDateInToday(date) {
            return "今天"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }

    // MARK: - Date Picker Sheet

    private var datePickerSheet: some View {
        NavigationStack {
            DatePicker("選擇日期", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .navigationTitle("選擇日期")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("完成") {
                            showDatePicker = false
                        }
                    }
                }
        }
        .presentationDetents([.medium])
    }

    // MARK: - Save

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
        isEditingNote = false

        withAnimation {
            showSavedFeedback = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showSavedFeedback = false
            }
        }
    }

    // MARK: - Saved Overlay

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
