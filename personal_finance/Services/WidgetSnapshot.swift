// ============================================================================
// MARK: - WidgetSnapshot.swift
// 模組：Services
//
// 功能說明：
//   這個檔案定義了 Widget 快照的資料模型，作為主 App 與 Widget Extension
//   之間的共享資料結構。主 App 透過 WidgetDataSync 寫入此快照，Widget
//   透過 load() 方法讀取。所有資料皆為 Codable，以 JSON 格式存取。
//
// 主要職責：
//   - 定義 Widget 顯示所需的完整資料結構（月收支、分類摘要、近期交易、帳戶）
//   - 提供金額字串轉 Decimal 的計算屬性，方便 Widget 端直接使用
//   - 提供從 App Group 共享容器載入快照的靜態方法
//
// 關鍵類型：
//   - WidgetSnapshot: 頂層快照結構，包含月收入/支出/結餘、顯示月份等
//   - CategorySummary: 支出分類摘要，含名稱、圖示、色碼、佔比百分比
//   - WidgetTransaction: 近期交易摘要，含分類資訊、備註、金額、收支類型
//   - AccountSummary: 帳戶摘要，含名稱、圖示、餘額
//
// 關鍵方法：
//   - load(): 從 App Group 共享容器讀取 JSON 檔案並解碼為 WidgetSnapshot
//
// 注意事項：
//   - 金額欄位以 String 儲存（如 monthlyIncomeString），搭配計算屬性
//     （如 monthlyIncome）轉換為 Decimal，確保精度不流失
//   - load() 方法在任何失敗情況下回傳 nil，Widget 應處理無資料的情境
//   - 此檔案需同時被主 App 與 Widget Extension 兩個 target 引用
// ============================================================================

import Foundation

// Codable snapshot model shared between App and Widget targets.
// The App writes this JSON via WidgetDataSync.updateSnapshot(),
// and the Widget reads it via WidgetSnapshot.load().

struct WidgetSnapshot: Codable {
    let date: Date
    let monthlyIncomeString: String
    let monthlyExpenseString: String
    let monthlyBalanceString: String
    let topCategories: [CategorySummary]
    let recentTransactions: [WidgetTransaction]
    let accounts: [AccountSummary]
    let displayMonth: String

    var monthlyIncome: Decimal { Decimal(string: monthlyIncomeString) ?? 0 }
    var monthlyExpense: Decimal { Decimal(string: monthlyExpenseString) ?? 0 }
    var monthlyBalance: Decimal { Decimal(string: monthlyBalanceString) ?? 0 }

    struct CategorySummary: Codable {
        let name: String
        let icon: String
        let colorHex: String
        let percentage: Double
    }

    struct WidgetTransaction: Codable {
        let categoryIcon: String
        let categoryName: String
        let note: String
        let amountString: String
        let isIncome: Bool

        var amount: Decimal { Decimal(string: amountString) ?? 0 }
    }

    struct AccountSummary: Codable {
        let name: String
        let icon: String
        let balanceString: String

        var balance: Decimal { Decimal(string: balanceString) ?? 0 }
    }

    // MARK: - Load from App Group (used by Widget)

    static func load() -> WidgetSnapshot? {
        let appGroupID = "group.com.firstfu.personal-finance"
        let snapshotFileName = "widget_snapshot.json"
        guard let url = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(snapshotFileName),
              let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }
}
