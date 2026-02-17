import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: FinanceWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.caption)
                Text("本月餘額")
                    .font(.caption)
                Spacer()
            }
            .foregroundStyle(.white.opacity(0.85))

            Spacer()

            Text(CurrencyFormatter.format(entry.monthlyBalance))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

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
