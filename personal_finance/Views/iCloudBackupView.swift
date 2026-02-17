// ============================================================================
// MARK: - iCloudBackupView.swift
// 模組：Views
//
// 功能說明：
//   備份與還原頁面，提供手動匯出備份檔與匯入還原功能。
//   備份格式為 JSON，透過系統的 fileExporter/fileImporter 與「檔案」App 整合，
//   支援儲存至 iCloud Drive 或透過 AirDrop 分享。
//
// 主要職責：
//   - 顯示 iCloud 同步說明資訊
//   - 匯出備份：透過 BackupService 建立備份文件，使用 fileExporter 儲存
//   - 匯入備份：透過 fileImporter 選取 JSON 檔案，解析後顯示還原確認
//   - 還原資料：確認後透過 BackupService 將備份資料寫入 ModelContext
//   - 操作過程中顯示 ProgressView 載入指示器
//   - 提供成功/錯誤提示 Alert
//
// UI 結構：
//   - Section（iCloud 同步說明）: iCloud 圖示與同步說明文字
//   - Section「手動備份」:
//     - 匯出備份檔按鈕（含載入中指示器）
//     - 匯入備份檔按鈕（含載入中指示器）
//     - Footer 說明文字
//   - fileExporter: 系統檔案匯出器，預設檔名含時間戳記
//   - fileImporter: 系統檔案匯入器，限定 .json 類型
//   - Alert「確認還原」: 顯示備份摘要（交易/分類/帳戶數量），確認後執行還原
//   - Alert「錯誤」: 顯示錯誤訊息
//   - Alert「完成」: 顯示成功訊息
//
// 資料依賴：
//   - @Environment(\.modelContext): 用於備份與還原資料
//   - @State isCreatingBackup / isRestoring: 操作進行中狀態
//   - @State exportDocument: 準備匯出的 BackupFileDocument
//   - @State importedDocument: 已匯入待確認的 BackupDocument
//   - BackupService: 負責建立備份、讀取備份檔、執行還原的服務層
//
// 注意事項：
//   - 匯入檔案時需處理 Security Scoped Resource 存取權限
//   - 還原操作會取代所有現有資料，且無法復原
//   - 備份檔名格式：「記帳備份_yyyy-MM-dd_HHmmss.json」
//   - 此頁面從 SettingsView 透過 NavigationLink 導航進入
// ============================================================================

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct iCloudBackupView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var isCreatingBackup = false
    @State private var isRestoring = false
    @State private var exportDocument: BackupFileDocument?
    @State private var showFileExporter = false
    @State private var showFileImporter = false
    @State private var showRestoreConfirmation = false
    @State private var importedDocument: BackupDocument?
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var showSuccessMessage = false
    @State private var successMessage = ""

    var body: some View {
        List {
            // MARK: - iCloud 同步說明
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "icloud.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iCloud 同步")
                            .font(.headline)
                        Text("資料會透過 iCloud 自動同步至你的所有裝置")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - 手動備份
            Section {
                // 匯出備份檔
                Button {
                    exportBackup()
                } label: {
                    HStack {
                        Label("匯出備份檔", systemImage: "square.and.arrow.up")
                        Spacer()
                        if isCreatingBackup {
                            ProgressView()
                        }
                    }
                }
                .disabled(isCreatingBackup || isRestoring)

                // 匯入備份檔
                Button {
                    showFileImporter = true
                } label: {
                    HStack {
                        Label("匯入備份檔", systemImage: "square.and.arrow.down")
                        Spacer()
                        if isRestoring {
                            ProgressView()
                        }
                    }
                }
                .disabled(isCreatingBackup || isRestoring)
            } header: {
                Text("手動備份")
            } footer: {
                Text("匯出的備份檔可儲存到「檔案」App、iCloud Drive 或透過 AirDrop 分享。匯入時將取代所有現有資料。")
            }
        }
        .navigationTitle("備份與還原")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $showFileExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: backupFileName()
        ) { result in
            switch result {
            case .success:
                successMessage = "備份檔案已匯出！"
                showSuccessMessage = true
            case .failure(let error):
                showError(error)
            }
            exportDocument = nil
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.json]
        ) { result in
            handleFileImport(result)
        }
        .alert("確認還原", isPresented: $showRestoreConfirmation) {
            Button("取消", role: .cancel) {
                importedDocument = nil
            }
            Button("還原", role: .destructive) {
                if let doc = importedDocument {
                    restoreBackup(doc)
                }
            }
        } message: {
            if let doc = importedDocument {
                Text("將還原 \(doc.summary.totalTransactions) 筆交易、\(doc.summary.totalCategories) 個分類和 \(doc.summary.totalAccounts) 個帳戶。\n\n此操作會取代所有現有資料，且無法復原。")
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

    private func exportBackup() {
        isCreatingBackup = true
        Task {
            do {
                let document = try BackupService.createBackup(context: modelContext)
                exportDocument = BackupFileDocument(document: document)
                showFileExporter = true
            } catch {
                showError(error)
            }
            isCreatingBackup = false
        }
    }

    private func handleFileImport(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            guard url.startAccessingSecurityScopedResource() else {
                showError(BackupError.fileReadFailed(
                    NSError(domain: "iCloudBackupView", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "無法存取所選檔案"])
                ))
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let document = try BackupService.loadBackup(from: url)
                importedDocument = document
                showRestoreConfirmation = true
            } catch {
                showError(error)
            }
        case .failure(let error):
            showError(error)
        }
    }

    private func restoreBackup(_ document: BackupDocument) {
        isRestoring = true
        Task {
            do {
                try BackupService.restore(document, into: modelContext)
                successMessage = "還原完成！已還原 \(document.summary.totalTransactions) 筆交易。"
                showSuccessMessage = true
            } catch {
                showError(error)
            }
            isRestoring = false
            importedDocument = nil
        }
    }

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    // MARK: - Helpers

    private func backupFileName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        return "記帳備份_\(formatter.string(from: .now)).json"
    }
}
