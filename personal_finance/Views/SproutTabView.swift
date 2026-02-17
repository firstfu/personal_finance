// ============================================================================
// MARK: - SproutTabView.swift
// 模組：Views
//
// 功能說明：
//   豆芽養成主頁面，顯示當前豆芽植物的成長狀態、進度、統計資訊。
//   使用 SF Symbols + SwiftUI 動畫呈現各成長階段。
// ============================================================================

import SwiftUI
import SwiftData

struct SproutTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<SproutPlant> { $0.isActive == true })
    private var activePlants: [SproutPlant]

    @State private var showHarvestGallery = false
    @State private var showHarvestCelebration = false
    @State private var animatePlant = false

    private var plant: SproutPlant? {
        activePlants.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 豆芽動畫區域
                    plantVisual
                        .padding(.top, 20)

                    // 成長進度
                    progressSection

                    // 成長資訊卡
                    statsCard

                    // 今日狀態
                    todayStatusCard

                    // 收成按鈕
                    if plant?.isReadyToHarvest == true {
                        harvestButton
                    }
                }
                .padding(.horizontal, AppTheme.horizontalPadding)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("我的豆芽")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showHarvestGallery = true
                    } label: {
                        Image(systemName: "trophy.fill")
                            .foregroundStyle(AppTheme.primary)
                    }
                }
            }
            .sheet(isPresented: $showHarvestGallery) {
                HarvestGalleryView()
            }
            .onAppear {
                ensurePlantExists()
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    animatePlant = true
                }
            }
            .overlay {
                if showHarvestCelebration {
                    harvestCelebrationOverlay
                }
            }
        }
    }

    // MARK: - 植物視覺呈現

    private var plantVisual: some View {
        VStack(spacing: 16) {
            ZStack {
                // 背景光暈
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [stageColor.opacity(0.2), .clear],
                            center: .center,
                            startRadius: 40,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)

                // 植物圖示
                Image(systemName: plant?.stageIcon ?? "leaf.circle")
                    .font(.system(size: 120))
                    .foregroundStyle(stageGradient)
                    .scaleEffect(animatePlant ? 1.05 : 0.95)
                    .shadow(color: stageColor.opacity(0.3), radius: 20, y: 10)
            }
            .frame(height: 260)

            Text(plant?.stageName ?? "種子")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.onBackground)
        }
    }

    // MARK: - 成長進度

    private var progressSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("成長階段")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Text("\(plant?.stageName ?? "種子") (\(plant?.currentStage ?? 0)/4)")
                    .font(.subheadline.bold())
                    .foregroundStyle(AppTheme.onBackground)
            }

            ProgressView(value: plant?.overallProgress ?? 0)
                .tint(stageColor)
                .scaleEffect(y: 1.5)

            HStack {
                Text("\(plant?.growthPoints ?? 0) 點")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                Spacer()
                Text("80 點")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    // MARK: - 成長資訊卡

    private var statsCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundStyle(AppTheme.primary)
                Text("成長資訊")
                    .font(.headline)
                    .foregroundStyle(AppTheme.onBackground)
                Spacer()
            }

            Divider()

            statsRow(label: "成長點數", value: "\(plant?.growthPoints ?? 0) / \(plant?.nextStageThreshold ?? 20)")
            statsRow(label: "連續天數", value: "\(plant?.consecutiveDays ?? 0) 天")
            statsRow(label: "培育天數", value: "\(plant?.totalDaysNurtured ?? 0) 天")
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }

    private func statsRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
                .foregroundStyle(AppTheme.onBackground)
        }
    }

    // MARK: - 今日狀態

    private var todayStatusCard: some View {
        let watered = hasWateredToday
        return VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: watered ? "checkmark.circle.fill" : "drop.circle")
                    .font(.title3)
                    .foregroundStyle(watered ? AppTheme.income : AppTheme.secondaryText)

                Text(watered ? "今日已記帳" : "今日尚未記帳")
                    .font(.headline)
                    .foregroundStyle(AppTheme.onBackground)

                Spacer()
            }

            Text(watered ? "繼續保持，豆芽正在成長～" : "去記帳澆灌你的豆芽吧！")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(watered ? AppTheme.income.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .stroke(watered ? AppTheme.income.opacity(0.2) : .clear, lineWidth: 1)
        )
    }

    // MARK: - 收成按鈕

    private var harvestButton: some View {
        Button {
            performHarvest()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("收成豆芽")
                    .font(.headline)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius)
                    .fill(AppTheme.primaryGradient)
            )
        }
    }

    // MARK: - 收成慶祝

    private var harvestCelebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.primary)

                Text("收成成功！")
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.onBackground)

                Text("豆芽已加入圖鑑，新的種子已種下")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(36)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
            .transition(.scale.combined(with: .opacity))
        }
        .animation(.easeInOut(duration: 0.3), value: showHarvestCelebration)
        .onTapGesture {
            withAnimation {
                showHarvestCelebration = false
            }
        }
    }

    // MARK: - Helpers

    private var hasWateredToday: Bool {
        guard let plant else { return false }
        guard let lastWatered = plant.lastWateredDate else { return false }
        return Calendar.current.isDateInToday(lastWatered)
    }

    private var stageColor: Color {
        switch plant?.currentStage ?? 0 {
        case 0: return .brown
        case 1: return Color(hex: "#8BC34A")
        case 2: return AppTheme.primary
        case 3: return AppTheme.primaryDark
        case 4: return Color(hex: "#FF9800")
        default: return AppTheme.primary
        }
    }

    private var stageGradient: LinearGradient {
        LinearGradient(
            colors: [stageColor, stageColor.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func ensurePlantExists() {
        if activePlants.isEmpty {
            let service = SproutGrowthService(modelContext: modelContext)
            _ = service.getActivePlant()
        }
    }

    private func performHarvest() {
        let service = SproutGrowthService(modelContext: modelContext)
        if service.harvestPlant() != nil {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            withAnimation {
                showHarvestCelebration = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showHarvestCelebration = false
                }
            }
        }
    }
}
