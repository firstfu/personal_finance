// ============================================================================
// MARK: - SettingsView.swift
// 模組：Views
//
// 功能說明：
//   應用程式設定頁面，提供外觀設定、帳戶管理、分類管理、
//   資料匯出/匯入/重設等功能的統一入口。
//
// 主要職責：
//   - 外觀模式切換（跟隨系統/淺色/深色）
//   - 帳戶管理：列出所有帳戶、新增帳戶、編輯帳戶、滑動刪除帳戶
//   - 分類管理：導航至 CategoryManagementView
//   - 載入/移除範例資料（Toggle 控制 SampleDataGenerator）
//   - 導航至備份與還原頁面（iCloudBackupView）
//   - 匯出交易紀錄為 CSV 檔案並提供分享功能
//   - 重設所有資料（含確認對話框），重設後重新植入預設分類與帳戶
//
// UI 結構：
//   - Section「外觀」: Picker 選擇外觀模式
//   - Section「帳戶管理」: ForEach 帳戶列表（含圖示、名稱、類型、餘額），底部「新增帳戶」按鈕
//   - Section「分類」: NavigationLink 至分類管理頁面
//   - Section「資料」: 範例資料開關、備份還原連結、CSV 匯出按鈕、重設按鈕
//   - Section「關於」: 顯示版本號
//   - Sheet: AccountFormView（新增/編輯帳戶）
//   - Alert: 重設確認對話框
//
// 資料依賴：
//   - @Environment(\.modelContext): 用於寫入與刪除資料
//   - @Query accounts: 全部帳戶，依 sortOrder 排序
//   - @Query allTransactions: 全部交易紀錄
//   - @AppStorage("appColorScheme"): 外觀模式偏好
//   - @AppStorage("showDemoData"): 範例資料顯示狀態
//
// 注意事項：
//   - 預設帳戶（isDefault == true）無法被滑動刪除
//   - 重設操作會刪除所有交易、帳戶、分類後重新植入預設資料
//   - 資料變更後皆呼叫 WidgetDataSync.updateSnapshot 同步 Widget
// ============================================================================

import SwiftUI
import SwiftData
import WidgetKit

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Account.sortOrder) private var accounts: [Account]
    @Query(sort: \Transaction.date) private var allTransactions: [Transaction]

    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("showDemoData") private var showDemoData = false
    @AppStorage("soundEffectsEnabled") private var soundEffectsEnabled = true

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

                // MARK: - 音效
                Section("音效") {
                    Toggle(isOn: $soundEffectsEnabled) {
                        Label("音效", systemImage: "speaker.wave.2")
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
                                Text(CurrencyFormatter.format(showDemoData ? account.demoBalance : account.currentBalance))
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
                    Toggle(isOn: $showDemoData) {
                        Label("載入範例資料", systemImage: "doc.text.magnifyingglass")
                    }
                    .onChange(of: showDemoData) { _, newValue in
                        if newValue {
                            SampleDataGenerator.insertSampleData(into: modelContext)
                        } else {
                            SampleDataGenerator.removeSampleData(from: modelContext)
                        }
                        WidgetDataSync.updateSnapshot(from: modelContext)
                    }

                    NavigationLink {
                        iCloudBackupView()
                    } label: {
                        Label("備份與還原", systemImage: "externaldrive.fill")
                    }

                    if let url = exportURL {
                        ShareLink(item: url) {
                            Label("分享匯出的 CSV", systemImage: "square.and.arrow.up")
                        }
                    }
                    Button {
                        let txToExport = allTransactions.filter { showDemoData ? $0.isDemoData : !$0.isDemoData }
                        exportURL = CSVExporter.exportToFile(transactions: txToExport)
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
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.large)
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
                Text("這將刪除所有交易紀錄、分類、帳戶及豆芽資料。此操作無法復原。")
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
        WidgetDataSync.updateSnapshot(from: modelContext)
    }

    private func resetAllData() {
        showDemoData = false
        for tx in allTransactions {
            modelContext.delete(tx)
        }
        // Delete non-default accounts only
        for account in accounts where !account.isDefault {
            modelContext.delete(account)
        }
        // Delete non-default categories only
        let descriptor = FetchDescriptor<Category>()
        if let allCategories = try? modelContext.fetch(descriptor) {
            for category in allCategories where !category.isDefault {
                modelContext.delete(category)
            }
        }
        // Delete all sprout plants and harvest records
        if let allPlants = try? modelContext.fetch(FetchDescriptor<SproutPlant>()) {
            for plant in allPlants {
                modelContext.delete(plant)
            }
        }
        if let allHarvests = try? modelContext.fetch(FetchDescriptor<HarvestRecord>()) {
            for record in allHarvests {
                modelContext.delete(record)
            }
        }
        try? modelContext.save()
        WidgetDataSync.updateSnapshot(from: modelContext)
    }
}
