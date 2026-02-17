import Foundation

enum CSVExporter {
    static func export(transactions: [Transaction]) -> String {
        var csv = "日期,類型,分類,帳戶,金額,備註\n"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"

        for tx in transactions.filter({ !$0.isDemoData }).sorted(by: { $0.date > $1.date }) {
            let dateStr = dateFormatter.string(from: tx.date)
            let typeStr = tx.type.displayName
            let categoryStr = tx.category?.name ?? "未分類"
            let accountStr = tx.account?.name ?? "未指定"
            let amountStr = "\(tx.amount)"
            let noteStr = tx.note.replacingOccurrences(of: ",", with: "，")
            csv += "\(dateStr),\(typeStr),\(categoryStr),\(accountStr),\(amountStr),\(noteStr)\n"
        }
        return csv
    }

    static func exportToFile(transactions: [Transaction]) -> URL? {
        let csv = export(transactions: transactions)
        let fileName = "personal_finance_export_\(Date.now.formatted(.dateTime.year().month().day().locale(Locale(identifier: "zh-TW")))).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }
}
