//
//  OnboardingView.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - OnboardingView.swift
// 模組：Views
//
// 功能說明：
//   首次啟動引導頁面，在使用者第一次開啟 App 時顯示歡迎畫面，
//   介紹應用程式的核心功能，引導使用者開始使用。
//
// 主要職責：
//   - 顯示品牌視覺（錢包圖示與品牌色漸層背景）
//   - 展示應用程式的核心價值訊息（輕鬆記錄每日收支）
//   - 提供「開始使用」按鈕，點擊後透過 @AppStorage 記錄完成狀態
//   - 完成引導後不再顯示（由 ContentView 根據 hasCompletedOnboarding 判斷）
//
// UI 結構：
//   - 全螢幕綠色背景（AppTheme.primary）
//   - wallet.bifold.fill 圖示: 品牌錢包圖示，深綠色
//   - 標題文字: 「輕鬆記錄每日收支」，白色粗體大字
//   - 副標題文字: 功能說明，白色半透明
//   - 「開始使用」按鈕: 深綠色背景圓角按鈕，點擊後切換至主畫面
//
// 資料依賴：
//   - @AppStorage("hasCompletedOnboarding"): 記錄是否已完成引導
//
// 注意事項：
//   - 按鈕點擊使用 withAnimation 包裹，確保切換至主畫面時有過場動畫
//   - 此頁面僅在 hasCompletedOnboarding == false 時由 ContentView 呈現
// ============================================================================

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        ZStack {
            AppTheme.primary.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "wallet.bifold.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(AppTheme.primaryDark)

                VStack(spacing: 12) {
                    Text("輕鬆記錄\n每日收支")
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)

                    Text("直覺的介面，幫助你輕鬆管理個人財務\n掌握收支狀況，達成理財目標")
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Button {
                    withAnimation {
                        hasCompletedOnboarding = true
                    }
                } label: {
                    Text("開始使用")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primaryDark)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.buttonCornerRadius))
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}
