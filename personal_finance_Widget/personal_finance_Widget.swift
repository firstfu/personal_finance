// ============================================================================
// MARK: - personal_finance_Widget.swift
// 模組：Widget
//
// 功能說明：
//   這個檔案定義了 iOS Widget Extension 的核心結構，包含 Widget 資料模型、
//   Timeline Provider、Entry View 路由以及 Widget 本體定義。
//
// 主要職責：
//   - FinanceWidgetEntry：Widget 時間線條目資料模型，包含月收支摘要、
//     分類排行、最近交易、帳戶餘額等資訊
//   - FinanceTimelineProvider：提供 Widget 的 placeholder、snapshot 與
//     timeline 資料，每 15 分鐘自動更新
//   - personal_finance_WidgetEntryView：根據 Widget 尺寸（small/medium/large）
//     路由至對應的子視圖
//   - personal_finance_Widget：Widget 主體定義，設定顯示名稱與支援尺寸
//
// 注意事項：
//   - 使用 StaticConfiguration，無需使用者自訂 Intent
//   - placeholder 使用寫死的範例資料供預覽顯示
//   - 支援三種尺寸：systemSmall、systemMedium、systemLarge
// ============================================================================

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct FinanceWidgetEntry: TimelineEntry {
    let date: Date
    let monthlyIncome: Decimal
    let monthlyExpense: Decimal
    let monthlyBalance: Decimal
    let topCategories: [CategorySummary]
    let recentTransactions: [WidgetTransaction]
    let accounts: [AccountSummary]
    let displayMonth: String

    struct CategorySummary {
        let name: String
        let icon: String
        let colorHex: String
        let percentage: Double
    }

    struct WidgetTransaction {
        let categoryIcon: String
        let categoryName: String
        let note: String
        let amount: Decimal
        let isIncome: Bool
    }

    struct AccountSummary {
        let name: String
        let icon: String
        let balance: Decimal
    }

    static let placeholder = FinanceWidgetEntry(
        date: .now,
        monthlyIncome: 45000,
        monthlyExpense: 32650,
        monthlyBalance: 12350,
        topCategories: [
            .init(name: "飲食", icon: "fork.knife", colorHex: "#FF9800", percentage: 35),
            .init(name: "交通", icon: "car.fill", colorHex: "#2196F3", percentage: 20),
            .init(name: "娛樂", icon: "gamecontroller.fill", colorHex: "#9C27B0", percentage: 15),
        ],
        recentTransactions: [
            .init(categoryIcon: "fork.knife", categoryName: "飲食", note: "午餐", amount: 120, isIncome: false),
            .init(categoryIcon: "car.fill", categoryName: "交通", note: "捷運", amount: 500, isIncome: false),
            .init(categoryIcon: "briefcase.fill", categoryName: "薪資", note: "2月薪水", amount: 45000, isIncome: true),
        ],
        accounts: [
            .init(name: "現金", icon: "banknote.fill", balance: 2350),
            .init(name: "銀行存款", icon: "building.columns.fill", balance: 8000),
            .init(name: "信用卡", icon: "creditcard.fill", balance: -2000),
        ],
        displayMonth: "2月"
    )
}

// MARK: - Timeline Provider

struct FinanceTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> FinanceWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (FinanceWidgetEntry) -> Void) {
        if context.isPreview {
            completion(.placeholder)
        } else {
            completion(WidgetDataProvider.fetchEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FinanceWidgetEntry>) -> Void) {
        let entry = WidgetDataProvider.fetchEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget Entry View

struct personal_finance_WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FinanceWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Definition

@main
struct personal_finance_Widget: Widget {
    let kind: String = "personal_finance_Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FinanceTimelineProvider()) { entry in
            personal_finance_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("月收支摘要")
        .description("查看本月收入、支出和餘額")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
