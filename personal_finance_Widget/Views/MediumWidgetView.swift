import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: FinanceWidgetEntry

    var body: some View {
        HStack(spacing: 0) {
            // Left: Summary
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.caption)
                    Text("本月收支")
                        .font(.caption)
                    Spacer()
                    Text(entry.displayMonth)
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.85))

                Text(CurrencyFormatter.format(entry.monthlyBalance))
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                Text("本月餘額")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 8))
                            Text("收入")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        Text(CurrencyFormatter.format(entry.monthlyIncome))
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 8))
                            Text("支出")
                                .font(.system(size: 9))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                        Text(CurrencyFormatter.format(entry.monthlyExpense))
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right: Top categories
            VStack(alignment: .leading, spacing: 6) {
                Text("支出分類")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.7))

                if entry.topCategories.isEmpty {
                    Text("尚無資料")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                } else {
                    ForEach(Array(entry.topCategories.enumerated()), id: \.offset) { _, cat in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: cat.colorHex))
                                .frame(width: 8, height: 8)
                            Image(systemName: cat.icon)
                                .font(.system(size: 10))
                                .foregroundStyle(.white)
                            Text(cat.name)
                                .font(.system(size: 11))
                                .foregroundStyle(.white)
                            Spacer()
                            Text("\(Int(cat.percentage))%")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [Color(hex: "#8BC34A"), Color(hex: "#2E7D32")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(URL(string: "personalfinance://home"))
    }
}
