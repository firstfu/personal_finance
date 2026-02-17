import SwiftUI
import SwiftData

struct iCloudBackupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isICloudAvailable = false
    @State private var backups: [BackupFileInfo] = []
    @State private var isCreatingBackup = false
    @State private var isRestoring = false
    @State private var lastBackupDate: Date?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showRestoreConfirmation = false
    @State private var selectedBackup: BackupFileInfo?
    @State private var showSuccessMessage = false
    @State private var successMessage = ""

    var body: some View {
        List {
            // MARK: - Backup Section
            Section {
                HStack {
                    Image(systemName: isICloudAvailable ? "icloud.fill" : "icloud.slash")
                        .foregroundStyle(isICloudAvailable ? .green : .secondary)
                    Text(isICloudAvailable ? "iCloud 已連線" : "iCloud 未連線")
                        .foregroundStyle(isICloudAvailable ? AppTheme.onBackground : .secondary)
                }

                if isICloudAvailable {
                    Button {
                        createBackup()
                    } label: {
                        HStack {
                            Label("備份到 iCloud", systemImage: "icloud.and.arrow.up")
                            Spacer()
                            if isCreatingBackup {
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isCreatingBackup || isRestoring)

                    if let date = lastBackupDate {
                        HStack {
                            Text("上次備份")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(date, format: .dateTime.year().month().day().hour().minute().locale(Locale(identifier: "zh-TW")))
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                } else {
                    Text("請在「設定」中登入 iCloud 帳號並啟用 iCloud Drive，才能使用備份功能。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("備份")
            }

            // MARK: - Backup List Section
            if isICloudAvailable {
                Section {
                    if backups.isEmpty {
                        Text("尚無備份檔案")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(backups) { backup in
                            Button {
                                selectedBackup = backup
                                showRestoreConfirmation = true
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(backup.createdAt, format: .dateTime.year().month().day().hour().minute().locale(Locale(identifier: "zh-TW")))
                                        .foregroundStyle(AppTheme.onBackground)
                                    HStack(spacing: 12) {
                                        if let summary = backup.summary {
                                            Text("\(summary.totalTransactions) 筆交易")
                                            Text("\(summary.totalCategories) 分類")
                                            Text("\(summary.totalAccounts) 帳戶")
                                        }
                                        Spacer()
                                        Text(formatFileSize(backup.fileSize))
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                            .disabled(isRestoring || isCreatingBackup)
                        }
                        .onDelete(perform: deleteBackups)
                    }
                } header: {
                    Text("可用的備份")
                } footer: {
                    if !backups.isEmpty {
                        Text("點擊備份檔案以還原，左滑可刪除。還原將取代所有現有資料。")
                    }
                }
            }
        }
        .navigationTitle("iCloud 備份與還原")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            checkICloudStatus()
            if isICloudAvailable {
                loadBackups()
            }
        }
        .refreshable {
            checkICloudStatus()
            if isICloudAvailable {
                loadBackups()
            }
        }
        .alert("確認還原", isPresented: $showRestoreConfirmation) {
            Button("取消", role: .cancel) {
                selectedBackup = nil
            }
            Button("還原", role: .destructive) {
                if let backup = selectedBackup {
                    restoreBackup(backup)
                }
            }
        } message: {
            if let backup = selectedBackup, let summary = backup.summary {
                Text("將還原 \(summary.totalTransactions) 筆交易、\(summary.totalCategories) 個分類和 \(summary.totalAccounts) 個帳戶。\n\n此操作會取代所有現有資料，且無法復原。")
            } else {
                Text("此操作會取代所有現有資料，且無法復原。確定要還原嗎？")
            }
        }
        .alert("錯誤", isPresented: $showError) {
            Button("確定") {}
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .alert("完成", isPresented: $showSuccessMessage) {
            Button("確定") {}
        } message: {
            Text(successMessage)
        }
    }

    // MARK: - Actions

    private func checkICloudStatus() {
        isICloudAvailable = BackupService.isICloudAvailable()
    }

    private func loadBackups() {
        do {
            backups = try BackupService.listBackups()
            lastBackupDate = backups.first?.createdAt
        } catch {
            showError(error)
        }
    }

    private func createBackup() {
        isCreatingBackup = true
        // Use Task to allow UI to update before potentially blocking operation
        Task {
            do {
                let document = try BackupService.createBackup(context: modelContext)
                _ = try BackupService.saveToICloud(document)
                loadBackups()
                successMessage = "備份完成！"
                showSuccessMessage = true
            } catch {
                showError(error)
            }
            isCreatingBackup = false
        }
    }

    private func restoreBackup(_ backup: BackupFileInfo) {
        isRestoring = true
        Task {
            do {
                let document = try BackupService.loadBackup(from: backup.url)
                try BackupService.restore(document, into: modelContext)
                successMessage = "還原完成！已還原 \(document.summary.totalTransactions) 筆交易。"
                showSuccessMessage = true
            } catch {
                showError(error)
            }
            isRestoring = false
            selectedBackup = nil
        }
    }

    private func deleteBackups(at offsets: IndexSet) {
        for index in offsets {
            let backup = backups[index]
            do {
                try BackupService.deleteBackup(at: backup.url)
            } catch {
                showError(error)
                return
            }
        }
        backups.remove(atOffsets: offsets)
        lastBackupDate = backups.first?.createdAt
    }

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    // MARK: - Helpers

    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
