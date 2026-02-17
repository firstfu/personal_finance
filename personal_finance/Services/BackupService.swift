import Foundation
import SwiftData

enum BackupService {
    private static let currentVersion = 1
    private static let backupDirectoryName = "Backups"
    private static let containerIdentifier = "iCloud.com.firstfu.com.personal-finance"

    // MARK: - iCloud Availability

    static func isICloudAvailable() -> Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    static func iCloudBackupDirectory() -> URL? {
        guard let containerURL = FileManager.default.url(forUbiquityContainerIdentifier: containerIdentifier) else {
            return nil
        }
        return containerURL.appendingPathComponent("Documents").appendingPathComponent(backupDirectoryName)
    }

    // MARK: - Create Backup

    static func createBackup(context: ModelContext) throws -> BackupDocument {
        let categoryDescriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        let accountDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        let transactionDescriptor = FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date)])

        let categories = try context.fetch(categoryDescriptor)
        let accounts = try context.fetch(accountDescriptor)
        let transactions = try context.fetch(transactionDescriptor)

        // Build ID mapping: SwiftData object -> backup UUID
        var categoryIdMap: [PersistentIdentifier: UUID] = [:]
        var accountIdMap: [PersistentIdentifier: UUID] = [:]

        let categoryDTOs = categories.map { category -> CategoryDTO in
            let backupId = UUID()
            categoryIdMap[category.persistentModelID] = backupId
            return CategoryDTO(
                backupId: backupId,
                name: category.name,
                icon: category.icon,
                colorHex: category.colorHex,
                type: category.type.rawValue,
                sortOrder: category.sortOrder,
                isDefault: category.isDefault
            )
        }

        let accountDTOs = accounts.map { account -> AccountDTO in
            let backupId = UUID()
            accountIdMap[account.persistentModelID] = backupId
            return AccountDTO(
                backupId: backupId,
                name: account.name,
                type: account.type.rawValue,
                icon: account.icon,
                colorHex: account.colorHex,
                initialBalance: "\(account.initialBalance)",
                sortOrder: account.sortOrder,
                isDefault: account.isDefault
            )
        }

        let transactionDTOs = transactions.map { tx -> TransactionDTO in
            let categoryBackupId: UUID? = if let cat = tx.category {
                categoryIdMap[cat.persistentModelID]
            } else {
                nil
            }
            let accountBackupId: UUID? = if let acc = tx.account {
                accountIdMap[acc.persistentModelID]
            } else {
                nil
            }
            return TransactionDTO(
                amount: "\(tx.amount)",
                type: tx.type.rawValue,
                categoryBackupId: categoryBackupId,
                accountBackupId: accountBackupId,
                note: tx.note,
                date: tx.date,
                createdAt: tx.createdAt
            )
        }

        let summary = BackupSummary(
            totalTransactions: transactionDTOs.count,
            totalCategories: categoryDTOs.count,
            totalAccounts: accountDTOs.count
        )

        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"

        return BackupDocument(
            version: currentVersion,
            createdAt: .now,
            appVersion: appVersion,
            summary: summary,
            categories: categoryDTOs,
            accounts: accountDTOs,
            transactions: transactionDTOs
        )
    }

    // MARK: - Save to iCloud

    static func saveToICloud(_ document: BackupDocument) throws -> URL {
        guard let directory = iCloudBackupDirectory() else {
            throw BackupError.iCloudNotAvailable
        }

        // Create directory if needed
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            } catch {
                throw BackupError.directoryCreationFailed
            }
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data: Data
        do {
            data = try encoder.encode(document)
        } catch {
            throw BackupError.encodingFailed(error)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let fileName = "Backup_\(formatter.string(from: document.createdAt)).json"
        let fileURL = directory.appendingPathComponent(fileName)

        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw BackupError.fileWriteFailed(error)
        }

        return fileURL
    }

    // MARK: - List Backups

    static func listBackups() throws -> [BackupFileInfo] {
        guard let directory = iCloudBackupDirectory() else {
            throw BackupError.iCloudNotAvailable
        }

        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: directory.path) else {
            return []
        }

        let contents: [URL]
        do {
            contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey, .creationDateKey])
        } catch {
            throw BackupError.fileReadFailed(error)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return contents
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> BackupFileInfo? in
                let attributes = try? fileManager.attributesOfItem(atPath: url.path)
                let fileSize = attributes?[.size] as? Int64 ?? 0
                let creationDate = attributes?[.creationDate] as? Date ?? .now

                // Try to read summary from file
                var summary: BackupSummary? = nil
                if let data = try? Data(contentsOf: url),
                   let doc = try? decoder.decode(BackupDocument.self, from: data) {
                    summary = doc.summary
                }

                return BackupFileInfo(
                    url: url,
                    fileName: url.lastPathComponent,
                    fileSize: fileSize,
                    createdAt: creationDate,
                    summary: summary
                )
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Load Backup

    static func loadBackup(from url: URL) throws -> BackupDocument {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: url.path) else {
            throw BackupError.fileNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BackupError.fileReadFailed(error)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let document: BackupDocument
        do {
            document = try decoder.decode(BackupDocument.self, from: data)
        } catch {
            throw BackupError.decodingFailed(error)
        }

        guard document.version <= currentVersion else {
            throw BackupError.versionIncompatible(document.version)
        }

        return document
    }

    // MARK: - Restore

    static func restore(_ document: BackupDocument, into context: ModelContext) throws {
        do {
            // Delete all existing data
            try context.delete(model: Transaction.self)
            try context.delete(model: Category.self)
            try context.delete(model: Account.self)

            // Restore categories
            var categoryMap: [UUID: Category] = [:]
            for dto in document.categories {
                let category = Category(
                    name: dto.name,
                    icon: dto.icon,
                    colorHex: dto.colorHex,
                    type: TransactionType(rawValue: dto.type) ?? .expense,
                    sortOrder: dto.sortOrder,
                    isDefault: dto.isDefault
                )
                context.insert(category)
                categoryMap[dto.backupId] = category
            }

            // Restore accounts
            var accountMap: [UUID: Account] = [:]
            for dto in document.accounts {
                let account = Account(
                    name: dto.name,
                    type: AccountType(rawValue: dto.type) ?? .cash,
                    icon: dto.icon,
                    colorHex: dto.colorHex,
                    initialBalance: Decimal(string: dto.initialBalance) ?? 0,
                    sortOrder: dto.sortOrder,
                    isDefault: dto.isDefault
                )
                context.insert(account)
                accountMap[dto.backupId] = account
            }

            // Restore transactions
            for dto in document.transactions {
                let transaction = Transaction(
                    amount: Decimal(string: dto.amount) ?? 0,
                    type: TransactionType(rawValue: dto.type) ?? .expense,
                    category: dto.categoryBackupId.flatMap { categoryMap[$0] },
                    account: dto.accountBackupId.flatMap { accountMap[$0] },
                    note: dto.note,
                    date: dto.date
                )
                transaction.createdAt = dto.createdAt
                context.insert(transaction)
            }

            try context.save()
        } catch let error as BackupError {
            throw error
        } catch {
            throw BackupError.restoreFailed(error)
        }
    }

    // MARK: - Delete Backup

    static func deleteBackup(at url: URL) throws {
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            throw BackupError.deleteFailed(error)
        }
    }
}
