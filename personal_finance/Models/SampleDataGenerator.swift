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
        let bank = account("銀行存款")
        let credit = account("信用卡")

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
        insert(context, amount: 280, type: .expense, cat: category("飲食", type: .expense), acc: credit, note: "晚餐聚會", date: daysAgo(2))
        insert(context, amount: 120, type: .expense, cat: category("飲食", type: .expense), acc: cash, note: "手搖飲", date: daysAgo(4))
        insert(context, amount: 500, type: .expense, cat: category("飲食", type: .expense), acc: credit, note: "朋友聚餐", date: daysAgo(8))
        insert(context, amount: 95, type: .expense, cat: category("飲食", type: .expense), acc: cash, note: "超商咖啡", date: daysAgo(12))
        insert(context, amount: 350, type: .expense, cat: category("飲食", type: .expense), acc: credit, note: "週末brunch", date: daysAgo(18))
        insert(context, amount: 180, type: .expense, cat: category("飲食", type: .expense), acc: cash, note: "夜市小吃", date: daysAgo(25))

        // 交通 x5
        insert(context, amount: 35, type: .expense, cat: category("交通", type: .expense), acc: cash, note: "公車", date: daysAgo(1))
        insert(context, amount: 280, type: .expense, cat: category("交通", type: .expense), acc: credit, note: "加油", date: daysAgo(7))
        insert(context, amount: 1500, type: .expense, cat: category("交通", type: .expense), acc: credit, note: "高鐵來回", date: daysAgo(14))
        insert(context, amount: 50, type: .expense, cat: category("交通", type: .expense), acc: cash, note: "捷運儲值", date: daysAgo(21))
        insert(context, amount: 250, type: .expense, cat: category("交通", type: .expense), acc: credit, note: "計程車", date: daysAgo(30))

        // 娛樂 x3
        insert(context, amount: 350, type: .expense, cat: category("娛樂", type: .expense), acc: credit, note: "電影票 x2", date: daysAgo(3))
        insert(context, amount: 1200, type: .expense, cat: category("娛樂", type: .expense), acc: credit, note: "KTV 包廂", date: daysAgo(10))
        insert(context, amount: 590, type: .expense, cat: category("娛樂", type: .expense), acc: credit, note: "串流訂閱年費", date: daysAgo(28))

        // 購物 x3
        insert(context, amount: 299, type: .expense, cat: category("購物", type: .expense), acc: credit, note: "手機殼", date: daysAgo(6))
        insert(context, amount: 1280, type: .expense, cat: category("購物", type: .expense), acc: credit, note: "運動鞋", date: daysAgo(16))
        insert(context, amount: 3500, type: .expense, cat: category("購物", type: .expense), acc: credit, note: "藍牙耳機", date: daysAgo(35))

        // 居住 x3
        insert(context, amount: 12000, type: .expense, cat: category("居住", type: .expense), acc: bank, note: "房租", date: daysAgo(2))
        insert(context, amount: 1800, type: .expense, cat: category("居住", type: .expense), acc: bank, note: "水電瓦斯", date: daysAgo(9))
        insert(context, amount: 499, type: .expense, cat: category("居住", type: .expense), acc: bank, note: "網路費", date: daysAgo(9))

        // 醫療 x2
        insert(context, amount: 200, type: .expense, cat: category("醫療", type: .expense), acc: cash, note: "感冒看診", date: daysAgo(11))
        insert(context, amount: 450, type: .expense, cat: category("醫療", type: .expense), acc: cash, note: "牙醫洗牙", date: daysAgo(40))

        // 教育 x2
        insert(context, amount: 350, type: .expense, cat: category("教育", type: .expense), acc: cash, note: "程式書籍", date: daysAgo(22))
        insert(context, amount: 680, type: .expense, cat: category("教育", type: .expense), acc: credit, note: "線上課程", date: daysAgo(45))

        // 其他支出 x1
        insert(context, amount: 150, type: .expense, cat: category("其他", type: .expense), acc: cash, note: "影印費", date: daysAgo(13))

        try? context.save()
    }

    static func removeSampleData(from context: ModelContext) {
        let predicate = #Predicate<Transaction> { $0.isDemoData == true }
        let descriptor = FetchDescriptor<Transaction>(predicate: predicate)
        guard let demoTransactions = try? context.fetch(descriptor) else { return }
        for tx in demoTransactions {
            context.delete(tx)
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
}
