// ============================================================================
// MARK: - SproutGrowthService.swift
// 模組：Services
//
// 功能說明：
//   豆芽養成遊戲的核心成長邏輯服務。
//   負責植物的取得/建立、澆灌成長、階段判定、收成等操作。
//
// 成長規則：
//   - 每次記帳成長 +3 點
//   - 每天第一筆額外獲得連續天數 bonus：+min(consecutiveDays - 1, 5)
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

    /// 澆灌植物（記帳後呼叫，每次記帳都會成長）
    func waterPlant() -> WaterResult {
        let plant = getActivePlant()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        let isFirstToday: Bool
        if let lastWatered = plant.lastWateredDate,
           calendar.isDate(lastWatered, inSameDayAs: today) {
            isFirstToday = false
        } else {
            isFirstToday = true
        }

        // 每天第一筆：更新連續天數和培育天數
        var bonus = 0
        if isFirstToday {
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
            bonus = min(plant.consecutiveDays - 1, 5)
            plant.totalDaysNurtured += 1
        }

        // 計算成長點數：每筆 +3，第一筆額外 +bonus
        let basePoints = 3
        let pointsEarned = basePoints + bonus

        plant.growthPoints += pointsEarned
        plant.lastWateredDate = today

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

    /// 移除重複的活躍植物（CloudKit 同步後可能產生重複）
    /// 保留成長點數最高的植物，同分則保留較早建立的
    static func removeDuplicateActivePlants(from context: ModelContext) {
        let descriptor = FetchDescriptor<SproutPlant>(
            predicate: #Predicate { $0.isActive == true }
        )
        guard let activePlants = try? context.fetch(descriptor),
              activePlants.count > 1 else { return }

        let sorted = activePlants.sorted {
            if $0.growthPoints != $1.growthPoints {
                return $0.growthPoints > $1.growthPoints
            }
            return $0.createdAt < $1.createdAt
        }
        for plant in sorted.dropFirst() {
            context.delete(plant)
        }
        try? context.save()
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
