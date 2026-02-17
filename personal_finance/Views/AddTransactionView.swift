import SwiftUI
import SwiftData

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
