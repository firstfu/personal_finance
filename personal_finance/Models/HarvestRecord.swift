// ============================================================================
// MARK: - HarvestRecord.swift
// 模組：Models
//
// 功能說明：
//   豆芽養成遊戲的收成紀錄 Model，記錄每次豆芽成熟收成的統計資料。
//   用於收成圖鑑頁面的展示。
// ============================================================================

import Foundation
import SwiftData

@Model final class HarvestRecord {
    var id: UUID = UUID()
    var harvestedAt: Date = Date.now
    var totalGrowthPoints: Int = 0
    var totalDaysNurtured: Int = 0
    var longestStreak: Int = 0
    var isDemoData: Bool = false

    init(totalGrowthPoints: Int, totalDaysNurtured: Int, longestStreak: Int, isDemoData: Bool = false) {
        self.totalGrowthPoints = totalGrowthPoints
        self.totalDaysNurtured = totalDaysNurtured
        self.longestStreak = longestStreak
        self.isDemoData = isDemoData
    }
}
