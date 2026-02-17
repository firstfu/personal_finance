// ============================================================================
// MARK: - HarvestGalleryView.swift
// 模組：Views
//
// 功能說明：
//   收成圖鑑頁面，以 LazyVGrid 展示所有歷次收成的豆芽紀錄。
//   每張卡片顯示收成日期、培育天數與最長連續天數。
// ============================================================================

import SwiftUI
import SwiftData

struct HarvestGalleryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HarvestRecord.harvestedAt, order: .reverse)
    private var records: [HarvestRecord]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    emptyState
                } else {
                    galleryGrid
                }
            }
            .navigationTitle("收成圖鑑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("關閉") { dismiss() }
                }
            }
        }
    }

    // MARK: - 圖鑑網格

    private var galleryGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(records) { record in
                    harvestCard(record)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    private func harvestCard(_ record: HarvestRecord) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tree.fill")
                .font(.system(size: 36))
                .foregroundStyle(AppTheme.primaryGradient)

            Text(formattedDate(record.harvestedAt))
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)

            VStack(spacing: 2) {
                HStack(spacing: 2) {
                    Image(systemName: "calendar")
                        .font(.system(size: 9))
                    Text("\(record.totalDaysNurtured)天")
                        .font(.caption2)
                }
                .foregroundStyle(AppTheme.secondaryText)

                HStack(spacing: 2) {
                    Image(systemName: "flame")
                        .font(.system(size: 9))
                    Text("\(record.longestStreak)天連續")
                        .font(.caption2)
                }
                .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - 空狀態

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.secondaryText.opacity(0.5))

            Text("尚無收成紀錄")
                .font(.headline)
                .foregroundStyle(AppTheme.onBackground)

            Text("開始記帳培育你的第一株豆芽吧！")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_TW")
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}
