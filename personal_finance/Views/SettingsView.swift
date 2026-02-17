import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]

    @AppStorage("appColorScheme") private var appColorScheme = "system"

    @State private var showAddCategory = false
    @State private var editingCategory: Category?
    @State private var showAddAccount = false
    @State private var editingAccount: Account?
    @State private var showResetConfirmation = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            List {
                // MARK: - 外觀
                Section("外觀") {
                    Picker("外觀模式", selection: $appColorScheme) {
                        Text("跟隨系統").tag("system")
                        Text("淺色").tag("light")
                        Text("深色").tag("dark")
                    }
                }

                // MARK: - 帳戶管理
                Section("帳戶管理") {
                    ForEach(accounts) { account in
                        Button {
                            editingAccount = account
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: account.colorHex).opacity(0.15))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: account.icon)
                                        .foregroundStyle(Color(hex: account.colorHex))
                                }
                                VStack(alignment: .leading) {
                                    Text(account.name)
                                        .foregroundStyle(AppTheme.onBackground)
                                    Text(account.type.displayName)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.secondaryText)
                                }
                                Spacer()
                                Text(CurrencyFormatter.format(account.currentBalance))
                                    .font(.body.monospacedDigit())
                                    .foregroundStyle(AppTheme.onBackground)
                            }
                        }
                    }
                    .onDelete(perform: deleteAccounts)

                    Button {
                        showAddAccount = true
                    } label: {
                        Label("新增帳戶", systemImage: "plus.circle")
                    }
                }

                // MARK: - 支出分類
                Section("支出分類") {
                    ForEach(categories.filter { $0.type == .expense }) { category in
                        categoryRow(category)
                    }
                    .onDelete { offsets in
                        deleteCategories(offsets: offsets, type: .expense)
                    }
                }

                // MARK: - 收入分類
                Section("收入分類") {
                    ForEach(categories.filter { $0.type == .income }) { category in
                        categoryRow(category)
                    }
                    .onDelete { offsets in
                        deleteCategories(offsets: offsets, type: .income)
                    }
                }

                // MARK: - 資料
                Section("資料") {
                    NavigationLink {
                        iCloudBackupView()
                    } label: {
                        Label("iCloud 備份與還原", systemImage: "icloud.and.arrow.up")
                    }

                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("分享匯出的 CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button {
                        exportURL = CSVExporter.exportToFile(transactions: allTransactions)
                    } label: {
                        Label("匯出交易紀錄 (CSV)", systemImage: "doc.text")
                    }

                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("重設所有資料", systemImage: "trash")
                    }
                }

                // MARK: - 關於
                Section("關於") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.1.0")
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar {
                Button {
                    showAddCategory = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddCategory) {
                CategoryFormView(mode: .add)
            }
            .sheet(item: $editingCategory) { category in
                CategoryFormView(mode: .edit(category))
            }
            .sheet(isPresented: $showAddAccount) {
                AccountFormView(mode: .add)
            }
            .sheet(item: $editingAccount) { account in
                AccountFormView(mode: .edit(account))
            }
            .alert("確認重設", isPresented: $showResetConfirmation) {
                Button("取消", role: .cancel) {}
                Button("重設", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("這將刪除所有交易紀錄和帳戶資料。此操作無法復原。")
            }
        }
    }

    private func categoryRow(_ category: Category) -> some View {
        Button {
            editingCategory = category
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color(hex: category.colorHex).opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: category.icon)
                        .foregroundStyle(Color(hex: category.colorHex))
                }
                Text(category.name)
                    .foregroundStyle(AppTheme.onBackground)
                Spacer()
                if category.isDefault {
                    Text("預設")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
        }
    }

    private func deleteCategories(offsets: IndexSet, type: TransactionType) {
        let filtered = categories.filter { $0.type == type }
        for index in offsets {
            let category = filtered[index]
            if !category.isDefault {
                modelContext.delete(category)
            }
        }
    }

    private func deleteAccounts(offsets: IndexSet) {
        for index in offsets {
            let account = accounts[index]
            if !account.isDefault {
                modelContext.delete(account)
            }
        }
    }

    private func resetAllData() {
        for tx in allTransactions {
            modelContext.delete(tx)
        }
        for account in accounts {
            modelContext.delete(account)
        }
        for category in categories {
            modelContext.delete(category)
        }
        try? modelContext.save()
        // Re-seed defaults
        DefaultCategories.seed(into: modelContext)
        DefaultCategories.seedAccounts(into: modelContext)
    }
}

// MARK: - CategoryFormView

struct CategoryFormView: View {
    enum Mode: Identifiable {
        case add
        case edit(Category)

        var id: String {
            switch self {
            case .add: return "add"
            case .edit(let cat): return "\(cat.persistentModelID.hashValue)"
            }
        }
    }

    let mode: Mode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var icon = "tag.fill"
    @State private var colorHex = "#607D8B"
    @State private var type: TransactionType = .expense

    private let iconOptions = [
        "fork.knife", "car.fill", "gamecontroller.fill", "bag.fill",
        "house.fill", "cross.case.fill", "book.fill", "tag.fill",
        "briefcase.fill", "star.fill", "gift.fill", "heart.fill"
    ]

    private let colorOptions = [
        "#FF9800", "#2196F3", "#9C27B0", "#E91E63",
        "#795548", "#F44336", "#3F51B5", "#607D8B",
        "#4CAF50", "#FFC107", "#00BCD4", "#8BC34A"
    ]

    var body: some View {
        NavigationStack {
            Form {
                TextField("名稱", text: $name)

                Picker("類型", selection: $type) {
                    Text("支出").tag(TransactionType.expense)
                    Text("收入").tag(TransactionType.income)
                }

                Section("圖標") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(iconOptions, id: \.self) { ic in
                            Button {
                                icon = ic
                            } label: {
                                Image(systemName: ic)
                                    .font(.title3)
                                    .frame(width: 40, height: 40)
                                    .background(icon == ic ? Color(hex: colorHex).opacity(0.2) : Color.clear)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
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
            .navigationTitle(isEditing ? "編輯分類" : "新增分類")
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
                if case .edit(let category) = mode {
                    name = category.name
                    icon = category.icon
                    colorHex = category.colorHex
                    type = category.type
                }
            }
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func save() {
        switch mode {
        case .add:
            let category = Category(
                name: name,
                icon: icon,
                colorHex: colorHex,
                type: type,
                sortOrder: 99
            )
            modelContext.insert(category)
        case .edit(let category):
            category.name = name
            category.icon = icon
            category.colorHex = colorHex
            category.type = type
        }
    }
}
