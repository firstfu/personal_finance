import SwiftUI
import SwiftData
import WidgetKit

struct AllTransactionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse)
    private var allTransactions: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Account.sortOrder) private var accounts: [Account]

    // 搜尋
    @State private var searchText = ""

    // 篩選
    @State private var filterType: TransactionType?
    @State private var filterAccount: Account?
    @State private var filterCategory: Category?
    @State private var filterDateRange: DateRangeOption = .all

    // 編輯 / 刪除
    @State private var selectedTransaction: Transaction?
    @State private var transactionToDelete: Transaction?
    @State private var showDeleteAlert = false

    enum DateRangeOption: String, CaseIterable {
        case all = "全部"
        case thisWeek = "本週"
        case thisMonth = "本月"
        case custom = "自訂"
    }

    @State private var customStartDate = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var customEndDate = Date.now
    @State private var showCustomDatePicker = false

    // MARK: - 篩選邏輯

    private var filteredTransactions: [Transaction] {
        allTransactions.filter { tx in
            // 類型篩選
            if let filterType, tx.type != filterType { return false }

            // 帳戶篩選
            if let filterAccount, tx.account?.id != filterAccount.id { return false }

            // 分類篩選
            if let filterCategory, tx.category?.id != filterCategory.id { return false }

            // 日期篩選
            switch filterDateRange {
            case .all: break
            case .thisWeek:
                guard let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start else { return false }
                if tx.date < weekStart { return false }
            case .thisMonth:
                guard let monthStart = Calendar.current.dateInterval(of: .month, for: .now)?.start else { return false }
                if tx.date < monthStart { return false }
            case .custom:
                let start = Calendar.current.startOfDay(for: customStartDate)
                let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: customEndDate)) ?? customEndDate
                if tx.date < start || tx.date >= end { return false }
            }

            // 搜尋
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                let matchNote = tx.note.lowercased().contains(query)
                let matchCategory = tx.category?.name.lowercased().contains(query) ?? false
                let matchAmount = tx.amountString.contains(query)
                let matchAccount = tx.account?.name.lowercased().contains(query) ?? false
                if !(matchNote || matchCategory || matchAmount || matchAccount) { return false }
            }

            return true
        }
    }

    private var groupedTransactions: [(String, [Transaction])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh-TW")
        formatter.dateStyle = .long

        let grouped = Dictionary(grouping: filteredTransactions) { tx in
            Calendar.current.startOfDay(for: tx.date)
        }

        return grouped.sorted { $0.key > $1.key }.map { (key, value) in
            (formatter.string(from: key), value.sorted { $0.date > $1.date })
        }
    }

    private var hasActiveFilters: Bool {
        filterType != nil || filterAccount != nil || filterCategory != nil || filterDateRange != .all
    }

    // MARK: - Body

    var body: some View {
        List {
            if filteredTransactions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: hasActiveFilters || !searchText.isEmpty ? "line.3.horizontal.decrease.circle" : "tray")
                        .font(.largeTitle)
                        .foregroundStyle(AppTheme.secondaryText)
                    Text(hasActiveFilters || !searchText.isEmpty ? "沒有符合條件的交易" : "尚無交易紀錄")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .listRowBackground(Color.clear)
            } else {
                ForEach(groupedTransactions, id: \.0) { dateString, transactions in
                    Section(header: sectionHeader(dateString: dateString, transactions: transactions)) {
                        ForEach(transactions) { tx in
                            TransactionRow(transaction: tx)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedTransaction = tx
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        transactionToDelete = tx
                                        showDeleteAlert = true
                                    } label: {
                                        Label("刪除", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        selectedTransaction = tx
                                    } label: {
                                        Label("編輯", systemImage: "pencil")
                                    }
                                    .tint(AppTheme.primary)
                                }
                        }
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "搜尋備註、分類、金額...")
        .navigationTitle("全部交易")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    filterMenu
                } label: {
                    Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        .foregroundStyle(hasActiveFilters ? AppTheme.primary : AppTheme.secondaryText)
                }
            }
        }
        .safeAreaInset(edge: .top) {
            if hasActiveFilters {
                activeFiltersBar
            }
        }
        .sheet(item: $selectedTransaction) { tx in
            EditTransactionView(transaction: tx)
        }
        .alert("確認刪除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) {
                transactionToDelete = nil
            }
            Button("刪除", role: .destructive) {
                if let tx = transactionToDelete {
                    deleteTransaction(tx)
                }
            }
        } message: {
            if let tx = transactionToDelete {
                Text("確定要刪除這筆 \(CurrencyFormatter.format(tx.amount)) 的\(tx.type.displayName)紀錄嗎？")
            }
        }
        .sheet(isPresented: $showCustomDatePicker) {
            customDatePickerSheet
        }
    }

    // MARK: - Section Header

    private func sectionHeader(dateString: String, transactions: [Transaction]) -> some View {
        HStack {
            Text(dateString)
            Spacer()
            let dayTotal = transactions.reduce(Decimal.zero) { result, tx in
                switch tx.type {
                case .income: result + tx.amount
                case .expense: result - tx.amount
                case .transfer: result
                }
            }
            Text((dayTotal >= 0 ? "+" : "") + CurrencyFormatter.format(dayTotal))
                .font(.caption.monospacedDigit())
                .foregroundStyle(dayTotal >= 0 ? AppTheme.income : AppTheme.expense)
        }
    }

    // MARK: - 篩選選單

    @ViewBuilder
    private var filterMenu: some View {
        // 類型
        Menu("類型") {
            Button("全部") { filterType = nil }
            ForEach([TransactionType.expense, .income, .transfer], id: \.self) { type in
                Button {
                    filterType = type
                } label: {
                    if filterType == type {
                        Label(type.displayName, systemImage: "checkmark")
                    } else {
                        Text(type.displayName)
                    }
                }
            }
        }

        // 帳戶
        Menu("帳戶") {
            Button("全部") { filterAccount = nil }
            ForEach(accounts) { account in
                Button {
                    filterAccount = account
                } label: {
                    if filterAccount?.id == account.id {
                        Label(account.name, systemImage: "checkmark")
                    } else {
                        Text(account.name)
                    }
                }
            }
        }

        // 分類
        Menu("分類") {
            Button("全部") { filterCategory = nil }
            ForEach(categories) { category in
                Button {
                    filterCategory = category
                } label: {
                    if filterCategory?.id == category.id {
                        Label(category.name, systemImage: "checkmark")
                    } else {
                        Text(category.name)
                    }
                }
            }
        }

        // 日期
        Menu("日期") {
            ForEach(DateRangeOption.allCases, id: \.self) { option in
                Button {
                    filterDateRange = option
                    if option == .custom {
                        showCustomDatePicker = true
                    }
                } label: {
                    if filterDateRange == option {
                        Label(option.rawValue, systemImage: "checkmark")
                    } else {
                        Text(option.rawValue)
                    }
                }
            }
        }

        Divider()

        // 清除篩選
        Button("清除所有篩選", role: .destructive) {
            filterType = nil
            filterAccount = nil
            filterCategory = nil
            filterDateRange = .all
        }
        .disabled(!hasActiveFilters)
    }

    // MARK: - 已啟用篩選條

    private var activeFiltersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                if let filterType {
                    filterChip(label: filterType.displayName) {
                        self.filterType = nil
                    }
                }
                if let filterAccount {
                    filterChip(label: filterAccount.name) {
                        self.filterAccount = nil
                    }
                }
                if let filterCategory {
                    filterChip(label: filterCategory.name) {
                        self.filterCategory = nil
                    }
                }
                if filterDateRange != .all {
                    filterChip(label: filterDateRange.rawValue) {
                        self.filterDateRange = .all
                    }
                }
            }
            .padding(.horizontal, AppTheme.horizontalPadding)
            .padding(.vertical, 6)
        }
        .background(.bar)
    }

    private func filterChip(label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption2)
            }
        }
        .foregroundStyle(AppTheme.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(AppTheme.primary.opacity(0.12))
        )
    }

    // MARK: - 自訂日期範圍

    private var customDatePickerSheet: some View {
        NavigationStack {
            Form {
                DatePicker("開始日期", selection: $customStartDate, displayedComponents: .date)
                DatePicker("結束日期", selection: $customEndDate, displayedComponents: .date)
            }
            .navigationTitle("自訂日期範圍")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        showCustomDatePicker = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        filterDateRange = .all
                        showCustomDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    // MARK: - 刪除交易

    private func deleteTransaction(_ transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
        WidgetDataSync.updateSnapshot(from: modelContext)
        transactionToDelete = nil
    }
}
