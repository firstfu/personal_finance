import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("appColorScheme") private var appColorScheme = "system"
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
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Transaction.self, Category.self, Account.self], inMemory: true)
}
