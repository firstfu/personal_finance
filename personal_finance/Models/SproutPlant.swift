// ============================================================================
// MARK: - SproutPlant.swift
// 模組：Models
//
// 功能說明：
//   豆芽養成遊戲的植物 Model，記錄當前培育中的豆芽狀態。
//   每次只有一株活躍植物（isActive == true），成熟收成後建立新植物。
//
// 成長階段：
//   0 = 種子、1 = 發芽、2 = 小苗、3 = 茂盛、4 = 開花結果
//
// 成長規則：
//   - 每日記帳至少 1 筆即可澆灌（基礎 10 點 + 連續天數 bonus）
//   - 階段門檻：0 / 20 / 40 / 60 / 80
//   - 漏記一天連續天數歸零，但不扣點數
// ============================================================================

import Foundation
import SwiftData

@Model final class SproutPlant {
    var id: UUID = UUID()
    var currentStage: Int = 0
    var growthPoints: Int = 0
    var createdAt: Date = Date.now
    var lastWateredDate: Date? = nil
    var consecutiveDays: Int = 0
    var isActive: Bool = true
    var harvestedAt: Date? = nil
    var totalDaysNurtured: Int = 0
    var isDemoData: Bool = false

    init() {}

    init(
        currentStage: Int,
        growthPoints: Int,
        createdAt: Date,
        lastWateredDate: Date?,
        consecutiveDays: Int,
        isActive: Bool,
        harvestedAt: Date?,
        totalDaysNurtured: Int,
        isDemoData: Bool = false
    ) {
        self.currentStage = currentStage
        self.growthPoints = growthPoints
        self.createdAt = createdAt
        self.lastWateredDate = lastWateredDate
        self.consecutiveDays = consecutiveDays
        self.isActive = isActive
        self.harvestedAt = harvestedAt
        self.totalDaysNurtured = totalDaysNurtured
        self.isDemoData = isDemoData
    }

    /// 階段名稱
    var stageName: String {
        switch currentStage {
        case 0: return "種子"
        case 1: return "發芽"
        case 2: return "小苗"
        case 3: return "茂盛"
        case 4: return "開花結果"
        default: return "種子"
        }
    }

    /// 當前階段對應的 SF Symbol
    var stageIcon: String {
        switch currentStage {
        case 0: return "leaf.circle"
        case 1: return "leaf"
        case 2: return "leaf.fill"
        case 3: return "tree"
        case 4: return "tree.fill"
        default: return "leaf.circle"
        }
    }

    /// 下一階段所需的成長點數門檻
    var nextStageThreshold: Int {
        switch currentStage {
        case 0: return 20
        case 1: return 40
        case 2: return 60
        case 3: return 80
        default: return 80
        }
    }

    /// 當前階段的起始點數
    var currentStageStartPoints: Int {
        switch currentStage {
        case 0: return 0
        case 1: return 20
        case 2: return 40
        case 3: return 60
        case 4: return 80
        default: return 0
        }
    }

    /// 當前階段內的進度（0.0 ~ 1.0）
    var stageProgress: Double {
        if currentStage >= 4 { return 1.0 }
        let rangeStart = currentStageStartPoints
        let rangeEnd = nextStageThreshold
        let range = rangeEnd - rangeStart
        guard range > 0 else { return 0 }
        return Double(growthPoints - rangeStart) / Double(range)
    }

    /// 總體進度（0.0 ~ 1.0）
    var overallProgress: Double {
        return min(Double(growthPoints) / 80.0, 1.0)
    }

    /// 是否已成熟可收成
    var isReadyToHarvest: Bool {
        currentStage >= 4
    }

    /// 根據階段數值取得階段名稱（靜態方法，供外部使用）
    static func stageNameFor(stage: Int) -> String {
        switch stage {
        case 0: return "種子"
        case 1: return "發芽"
        case 2: return "小苗"
        case 3: return "茂盛"
        case 4: return "開花結果"
        default: return "種子"
        }
    }
}
