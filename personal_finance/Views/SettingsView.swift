import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]

    @AppStorage("appColorScheme") private var appColorScheme = "system"

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

                // MARK: - 分類
                Section("分類") {
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Label("分類管理", systemImage: "tag")
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
                        Text("2.0.0")
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                }
            }
            .navigationTitle("設定")
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

    private func deleteAccounts(offsets: IndexSet) {
        for index in offsets {
            let account = accounts[index]
            if !account.isDefault {
                modelContext.delete(account)
            }
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func resetAllData() {
        for tx in allTransactions {
            modelContext.delete(tx)
        }
        for account in accounts {
            modelContext.delete(account)
        }
        // Fetch categories via descriptor for deletion
        let descriptor = FetchDescriptor<Category>()
        if let allCategories = try? modelContext.fetch(descriptor) {
            for category in allCategories {
                modelContext.delete(category)
            }
        }
        try? modelContext.save()
        // Re-seed defaults
        DefaultCategories.seed(into: modelContext)
        DefaultCategories.seedAccounts(into: modelContext)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
