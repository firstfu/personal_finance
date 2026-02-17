// ============================================================================
// MARK: - ContentView.swift
// 模組：App 根視圖
//
// 功能說明：
//   這個檔案定義了應用程式的根視圖，負責管理主要的 TabView 導航結構
//   以及首次啟動時的 Onboarding 流程判斷。
//
// 主要職責：
//   - 根據 hasCompletedOnboarding 狀態決定顯示 OnboardingView 或主畫面
//   - 管理四個主要分頁：首頁（HomeView）、記帳（AddTransactionView）、
//     分析（AnalyticsView）、設定（SettingsView）
//   - 透過 @AppStorage 管理色彩模式偏好（系統/淺色/深色）
//   - 處理 Deep Link（personalfinance:// scheme）導航至對應分頁
//
// 注意事項：
//   - 色彩模式透過 preferredColorScheme 套用至整個視圖階層
//   - TabView 的 tint 色彩使用 AppTheme.primaryDark 品牌色
// ============================================================================

import SwiftUI
import SwiftData
import UIKit

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appColorScheme") private var appColorScheme = "system"
    @AppStorage("showDemoData") private var showDemoData = false
    @State private var selectedTab = 0

    private var colorScheme: ColorScheme? {
        switch appColorScheme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                mainTabView
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(colorScheme)
        .onOpenURL { url in
            if url.scheme == "personalfinance" {
                selectedTab = 0
            }
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("首頁", systemImage: "house.fill")
                }
                .tag(0)

            AddTransactionView()
                .tabItem {
                    Label("記帳", systemImage: "plus.circle.fill")
                }
                .tag(1)

            AnalyticsView()
                .tabItem {
                    Label("分析", systemImage: "chart.bar.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("設定", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(AppTheme.primaryDark)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.stackedLayoutAppearance.normal.iconColor = .systemGray
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray]
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
        .overlay(alignment: .top) {
            if showDemoData {
                HStack(spacing: 6) {
                    Image(systemName: "eye.trianglebadge.exclamationmark")
                        .font(.caption.bold())
                    Text("範例資料模式")
                        .font(.caption.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(AppTheme.primary.opacity(0.9))
                .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self], inMemory: true)
}
