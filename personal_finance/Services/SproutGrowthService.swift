// ============================================================================
// MARK: - SproutGrowthService.swift
// 模組：Services
//
// 功能說明：
//   豆芽養成遊戲的核心成長邏輯服務。
//   負責植物的取得/建立、澆灌成長、階段判定、收成等操作。
//
// 成長規則：
//   - 基礎點數：10/天
//   - 連續天數 bonus：+min(consecutiveDays - 1, 5)
//   - 漏記一天：連續天數歸零，但不扣點數
//   - 階段門檻：0(種子) / 20(發芽) / 40(小苗) / 60(茂盛) / 80(開花結果)
// ============================================================================

import Foundation
import SwiftData

struct WaterResult {
    let didGrow: Bool
    let newStage: Int?
    let pointsEarned: Int
}

struct SproutGrowthService {
    let modelContext: ModelContext

    /// 取得當前活躍植物，若無則建立新植物
    func getActivePlant() -> SproutPlant {
        let descriptor = FetchDescriptor<SproutPlant>(
            predicate: #Predicate { $0.isActive == true }
        )
        if let plant = try? modelContext.fetch(descriptor).first {
            return plant
        }
        let newPlant = SproutPlant()
        modelContext.insert(newPlant)
        try? modelContext.save()
        return newPlant
    }

    /// 澆灌植物（記帳後呼叫）
    func waterPlant() -> WaterResult {
        let plant = getActivePlant()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        // 今日已澆灌過，不重複計算
        if let lastWatered = plant.lastWateredDate,
           calendar.isDate(lastWatered, inSameDayAs: today) {
            return WaterResult(didGrow: false, newStage: nil, pointsEarned: 0)
        }

        // 判斷是否連續
        if let lastWatered = plant.lastWateredDate {
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            if calendar.isDate(lastWatered, inSameDayAs: yesterday) {
                plant.consecutiveDays += 1
            } else {
                plant.consecutiveDays = 1
            }
        } else {
            plant.consecutiveDays = 1
        }

        // 計算成長點數
        let basePoints = 10
        let bonus = min(plant.consecutiveDays - 1, 5)
        let pointsEarned = basePoints + bonus

        plant.growthPoints += pointsEarned
        plant.lastWateredDate = today
        plant.totalDaysNurtured += 1

        // 判斷階段變化
        let oldStage = plant.currentStage
        let newStage = Self.stageForPoints(plant.growthPoints)
        plant.currentStage = newStage

        try? modelContext.save()

        let didStageUp = newStage > oldStage
        return WaterResult(
            didGrow: true,
            newStage: didStageUp ? newStage : nil,
            pointsEarned: pointsEarned
        )
    }

    /// 收成植物
    func harvestPlant() -> HarvestRecord? {
        let plant = getActivePlant()
        guard plant.isReadyToHarvest else { return nil }

        // 建立收成紀錄
        let record = HarvestRecord(
            totalGrowthPoints: plant.growthPoints,
            totalDaysNurtured: plant.totalDaysNurtured,
            longestStreak: plant.consecutiveDays
        )
        modelContext.insert(record)

        // 標記舊植物為非活躍
        plant.isActive = false
        plant.harvestedAt = Date.now

        // 建立新植物
        let newPlant = SproutPlant()
        modelContext.insert(newPlant)

        try? modelContext.save()
        return record
    }

    /// 檢查今日是否已澆灌
    func hasWateredToday() -> Bool {
        let plant = getActivePlant()
        guard let lastWatered = plant.lastWateredDate else { return false }
        return Calendar.current.isDateInToday(lastWatered)
    }

    /// 根據成長點數計算階段
    static func stageForPoints(_ points: Int) -> Int {
        switch points {
        case ..<20: return 0
        case 20..<40: return 1
        case 40..<60: return 2
        case 60..<80: return 3
        default: return 4
        }
    }
}
