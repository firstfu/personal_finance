// ============================================================================
// MARK: - SampleDataGenerator.swift
// 模組：Models
//
// 功能說明：
//   提供範例（Demo）交易資料的產生與清除功能。
//   用於展示 App 功能或開發測試，所有範例資料皆標記 isDemoData = true。
//
// 主要職責：
//   - 產生擬真的交易範例資料（涵蓋所有預設分類與帳戶）
//   - 提供一鍵清除所有範例資料的功能
//   - 確保範例資料涵蓋多種時間跨度（當天至 45 天前）
//
// 關鍵方法：
//   - insertSampleData(into:): 插入範例資料至指定的 ModelContext
//     包含 6 筆收入（薪資 x3、獎金 x1、投資 x1、其他 x1）
//     以及 27 筆支出（飲食 x8、交通 x5、娛樂 x3、購物 x3、居住 x3、
//     醫療 x2、教育 x2、其他 x1），共計 33 筆交易
//   - removeSampleData(from:): 刪除所有 isDemoData == true 的交易記錄
//   - insert(_:amount:type:cat:acc:note:date:): 私有輔助方法，建立單筆交易
//
// 注意事項：
//   - insertSampleData 會先呼叫 removeSampleData 清除舊範例，避免重複
//   - 範例資料依賴預設分類與帳戶已存在（需先執行 DefaultCategories.seed）
//   - 分類與帳戶以名稱比對（非 seedIdentifier），若名稱變更可能匹配失敗
//   - 金額以整數 Int 傳入，內部轉為 Decimal 儲存
// ============================================================================

import Foundation
import SwiftData

enum SampleDataGenerator {
    static func insertSampleData(into context: ModelContext) {
        // Remove existing demo data first to prevent duplicates
        removeSampleData(from: context)

        // Fetch categories and accounts by name
        let categoryDescriptor = FetchDescriptor<Category>()
        let accountDescriptor = FetchDescriptor<Account>()
        guard let categories = try? context.fetch(categoryDescriptor),
              let accounts = try? context.fetch(accountDescriptor) else { return }

        func category(_ name: String, type: TransactionType) -> Category? {
            categories.first { $0.name == name && $0.type == type }
        }
        func account(_ name: String) -> Account? {
            accounts.first { $0.name == name }
        }

        let calendar = Calendar.current
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
        }

        let cash = account("現金")
        let bank = account("合庫")

        // -- 收入 --
        // 薪資 x3
        insert(context, amount: 48000, type: .income, cat: category("薪資", type: .income), acc: bank, note: "本月薪資", date: daysAgo(1))
        insert(context, amount: 48000, type: .income, cat: category("薪資", type: .income), acc: bank, note: "上月薪資", date: daysAgo(31))
        insert(context, amount: 48000, type: .income, cat: category("薪資", type: .income), acc: bank, note: "前月薪資", date: daysAgo(62))
        // 獎金 x1
        insert(context, amount: 5000, type: .income, cat: category("獎金", type: .income), acc: bank, note: "績效獎金", date: daysAgo(5))
        // 投資 x1
        insert(context, amount: 2300, type: .income, cat: category("投資", type: .income), acc: bank, note: "股票股利", date: daysAgo(15))
        // 其他收入 x1
        insert(context, amount: 800, type: .income, cat: category("其他", type: .income), acc: cash, note: "二手書出售", date: daysAgo(20))

        // -- 支出 --
        // 飲食 x8
        insert(context, amount: 85, type: .expense, cat: category("飲食", type: .expense), acc: cash, note: "早餐 蛋餅加奶茶", date: daysAgo(0))
        insert(context, amount: 150, type: .expense, cat: category("飲食", type: .expense), acc: cash, note: "午餐便當", date: daysAgo(0))
        insert(context, amount: 280, type: .expense, cat: category("飲食", type: .expense), acc: bank, note: "晚餐聚會", date: daysAgo(2))
        insert(context, amount: 120, type: .expense, cat: category("飲食", type: .expense), acc: cash, note: "手搖飲", date: daysAgo(4))
        insert(context, amount: 500, type: .expense, cat: category("飲食", type: .expense), acc: bank, note: "朋友聚餐", date: daysAgo(8))
        insert(context, amount: 95, type: .expense, cat: category("飲食", type: .expense), acc: cash, note: "超商咖啡", date: daysAgo(12))
        insert(context, amount: 350, type: .expense, cat: category("飲食", type: .expense), acc: bank, note: "週末brunch", date: daysAgo(18))
        insert(context, amount: 180, type: .expense, cat: category("飲食", type: .expense), acc: cash, note: "夜市小吃", date: daysAgo(25))

        // 交通 x5
        insert(context, amount: 35, type: .expense, cat: category("交通", type: .expense), acc: cash, note: "公車", date: daysAgo(1))
        insert(context, amount: 280, type: .expense, cat: category("交通", type: .expense), acc: bank, note: "加油", date: daysAgo(7))
        insert(context, amount: 1500, type: .expense, cat: category("交通", type: .expense), acc: bank, note: "高鐵來回", date: daysAgo(14))
        insert(context, amount: 50, type: .expense, cat: category("交通", type: .expense), acc: cash, note: "捷運儲值", date: daysAgo(21))
        insert(context, amount: 250, type: .expense, cat: category("交通", type: .expense), acc: bank, note: "計程車", date: daysAgo(30))

        // 娛樂 x3
        insert(context, amount: 350, type: .expense, cat: category("娛樂", type: .expense), acc: bank, note: "電影票 x2", date: daysAgo(3))
        insert(context, amount: 1200, type: .expense, cat: category("娛樂", type: .expense), acc: bank, note: "KTV 包廂", date: daysAgo(10))
        insert(context, amount: 590, type: .expense, cat: category("娛樂", type: .expense), acc: bank, note: "串流訂閱年費", date: daysAgo(28))

        // 購物 x3
        insert(context, amount: 299, type: .expense, cat: category("購物", type: .expense), acc: bank, note: "手機殼", date: daysAgo(6))
        insert(context, amount: 1280, type: .expense, cat: category("購物", type: .expense), acc: bank, note: "運動鞋", date: daysAgo(16))
        insert(context, amount: 3500, type: .expense, cat: category("購物", type: .expense), acc: bank, note: "藍牙耳機", date: daysAgo(35))

        // 居住 x3
        insert(context, amount: 12000, type: .expense, cat: category("居住", type: .expense), acc: bank, note: "房租", date: daysAgo(2))
        insert(context, amount: 1800, type: .expense, cat: category("居住", type: .expense), acc: bank, note: "水電瓦斯", date: daysAgo(9))
        insert(context, amount: 499, type: .expense, cat: category("居住", type: .expense), acc: bank, note: "網路費", date: daysAgo(9))

        // 醫療 x2
        insert(context, amount: 200, type: .expense, cat: category("醫療", type: .expense), acc: cash, note: "感冒看診", date: daysAgo(11))
        insert(context, amount: 450, type: .expense, cat: category("醫療", type: .expense), acc: cash, note: "牙醫洗牙", date: daysAgo(40))

        // 教育 x2
        insert(context, amount: 350, type: .expense, cat: category("教育", type: .expense), acc: cash, note: "程式書籍", date: daysAgo(22))
        insert(context, amount: 680, type: .expense, cat: category("教育", type: .expense), acc: bank, note: "線上課程", date: daysAgo(45))

        // 其他支出 x1
        insert(context, amount: 150, type: .expense, cat: category("其他", type: .expense), acc: cash, note: "影印費", date: daysAgo(13))

        // -- 豆芽養成 --
        insertSproutData(into: context, daysAgo: daysAgo)

        try? context.save()
    }

    static func removeSampleData(from context: ModelContext) {
        let predicate = #Predicate<Transaction> { $0.isDemoData == true }
        let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
        if let demoTransactions = try? context.fetch(descriptor) {
            for tx in demoTransactions {
                context.delete(tx)
            }
        }

        let sproutPredicate = #Predicate<SproutPlant> { $0.isDemoData == true }
        let sproutDescriptor = FetchDescriptor<SproutPlant>(predicate: sproutPredicate)
        if let demoPlants = try? context.fetch(sproutDescriptor) {
            for plant in demoPlants {
                context.delete(plant)
            }
        }

        let harvestPredicate = #Predicate<HarvestRecord> { $0.isDemoData == true }
        let harvestDescriptor = FetchDescriptor<HarvestRecord>(predicate: harvestPredicate)
        if let demoRecords = try? context.fetch(harvestDescriptor) {
            for record in demoRecords {
                context.delete(record)
            }
        }

        try? context.save()
    }

    private static func insert(
        _ context: ModelContext,
        amount: Int,
        type: TransactionType,
        cat: Category?,
        acc: Account?,
        note: String,
        date: Date
    ) {
        let tx = Transaction(
            amount: Decimal(amount),
            type: type,
            category: cat,
            account: acc,
            note: note,
            date: date,
            isDemoData: true
        )
        context.insert(tx)
    }

    /// 插入豆芽養成範例資料：1 株活躍植物（小苗階段）+ 2 筆收成紀錄
    private static func insertSproutData(into context: ModelContext, daysAgo: (Int) -> Date) {
        // 已收成的植物 1（90 天前開始，60 天前收成）
        let harvested1 = SproutPlant(
            currentStage: 4,
            growthPoints: 85,
            createdAt: daysAgo(90),
            lastWateredDate: daysAgo(60),
            consecutiveDays: 8,
            isActive: false,
            harvestedAt: daysAgo(60),
            totalDaysNurtured: 18,
            isDemoData: true
        )
        context.insert(harvested1)

        let record1 = HarvestRecord(totalGrowthPoints: 85, totalDaysNurtured: 18, longestStreak: 8, isDemoData: true)
        record1.harvestedAt = daysAgo(60)
        context.insert(record1)

        // 已收成的植物 2（55 天前開始，30 天前收成）
        let harvested2 = SproutPlant(
            currentStage: 4,
            growthPoints: 92,
            createdAt: daysAgo(55),
            lastWateredDate: daysAgo(30),
            consecutiveDays: 12,
            isActive: false,
            harvestedAt: daysAgo(30),
            totalDaysNurtured: 22,
            isDemoData: true
        )
        context.insert(harvested2)

        let record2 = HarvestRecord(totalGrowthPoints: 92, totalDaysNurtured: 22, longestStreak: 12, isDemoData: true)
        record2.harvestedAt = daysAgo(30)
        context.insert(record2)

        // 已收成的植物 3（25 天前開始，10 天前收成）
        let harvested3 = SproutPlant(
            currentStage: 4,
            growthPoints: 80,
            createdAt: daysAgo(25),
            lastWateredDate: daysAgo(10),
            consecutiveDays: 5,
            isActive: false,
            harvestedAt: daysAgo(10),
            totalDaysNurtured: 12,
            isDemoData: true
        )
        context.insert(harvested3)

        let record3 = HarvestRecord(totalGrowthPoints: 80, totalDaysNurtured: 12, longestStreak: 5, isDemoData: true)
        record3.harvestedAt = daysAgo(10)
        context.insert(record3)
    }
}
