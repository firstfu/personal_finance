import Foundation
import SwiftData
import UniformTypeIdentifiers
import SwiftUI

// MARK: - BackupFileDocument for fileExporter/fileImporter

struct BackupFileDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let document: BackupDocument

    init(document: BackupDocument) {
        self.document = document
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw BackupError.fileReadFailed(
                NSError(domain: "BackupFileDocument", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "無法讀取檔案內容"])
            )
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            document = try decoder.decode(BackupDocument.self, from: data)
        } catch {
            throw BackupError.decodingFailed(error)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(document)
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - BackupService

enum BackupService {
    private static let currentVersion = 1

    // MARK: - Create Backup

    static func createBackup(context: ModelContext) throws -> BackupDocument {
        let categoryDescriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\.sortOrder)])
        let accountDescriptor = FetchDescriptor<Account>(sortBy: [SortDescriptor(\.sortOrder)])
        let transactionDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { $0.isDemoData == false },
            sortBy: [SortDescriptor(\.date)]
        )

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

    // MARK: - Load Backup from URL (for fileImporter)

    static func loadBackup(from url: URL) throws -> BackupDocument {
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
}
