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
