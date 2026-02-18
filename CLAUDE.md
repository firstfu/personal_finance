# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS/iPadOS 個人記帳應用程式（繁體中文介面），使用 Swift + SwiftUI + SwiftData 建構。

- Bundle ID: `com.firstfu.com.personal-finance`
- Development Team: `WY468E45SJ`
- 部署目標: iOS 26.2，支援 iPhone 與 iPad
- 無外部套件依賴，僅使用 Apple 原生框架（SwiftUI、SwiftData、Charts、SpriteKit、AVFoundation）
- 已設定 CloudKit entitlements（`iCloud.com.firstfu.com.personal-finance`）
- Deep link scheme: `personalfinance://`

## Build & Test Commands

```bash
# 建置
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build

# 執行單元測試（Swift Testing 框架）
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests

# 執行 UI 測試（XCTest 框架）
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeUITests
```

## Architecture

無正式架構模式（無 ViewModel 層）。業務邏輯以 computed properties 直接寫在 View 中。

### 關鍵 Swift 設定
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — 所有型別預設為 `@MainActor` 隔離
- `SWIFT_APPROACHABLE_CONCURRENCY = YES` — 啟用結構化並行最佳實踐
- SwiftData 使用磁碟儲存（`isStoredInMemoryOnly: false`）

### Targets
- `personal_finance` — 主 App
- `personal_finance_Widget` — Widget Extension（App Group: `group.com.firstfu.personal-finance`）
- `personal_financeTests` — 單元測試（Swift Testing）
- `personal_financeUITests` — UI 測試（XCTest）

### 資料層
- **五個 SwiftData Model**：`Transaction`、`Category`、`Account`、`SproutPlant`、`HarvestRecord`，全部需在 schema 中註冊
- **Schema 版本**：V1（基礎三表）→ V2（CloudKit 相容）→ V3（新增 SproutPlant + HarvestRecord），均為 lightweight migration
- `ModelContainer` 在 `personal_financeApp.swift` 建立並注入環境
- App 啟動時透過 `DefaultCategories.seed()` 植入預設分類（36 支出 + 14 收入）與帳戶（4 個：現金/合庫/土銀/LinePay），以 `seedIdentifier` 去重
- 金額儲存為 `amountString: String`，透過 `@Transient var amount: Decimal` 存取，確保精度；僅在 Charts 渲染時轉為 `Double`
- `TransactionType`：`.income | .expense | .transfer | .adjustment`
- `AccountType`：`.cash | .bank | .creditCard | .eWallet`
- 關聯：`Transaction -> Category`（多對一，nullify）、`Transaction -> Account`（多對一，nullify）、`Transaction -> transferToAccount`（轉帳對象，nullify）

### 豆芽養成功能
- `SproutPlant`：當前培育中的豆芽，5 個成長階段（種子→發芽→小苗→茂盛→開花結果）
- `HarvestRecord`：收成紀錄，用於圖鑑展示
- `SproutGrowthService`：成長邏輯核心（每次記帳 +3 點 + 連續天數 bonus `min(consecutiveDays-1, 5)`）
- 階段門檻：0 / 20 / 40 / 60 / 80 點
- 記帳後自動澆灌，同一天多次記帳只觸發一次成長
- 使用 SpriteKit 2.5D Parallax 動畫（SKShapeNode 貝茲曲線繪製、SKEmitterNode 粒子效果）
- SpriteKit 檔案位於 `SpriteKit/` 目錄：SproutScene、PlantNode、PotNode、GroundNode、BackgroundNode、ParticleEffects

### UI 層
- 根視圖 `ContentView` 使用 `TabView`（首頁/記帳/豆芽/分析/設定），首次啟動顯示 `OnboardingView`
- 透過 `@Query` 取得資料，`@Environment(\.modelContext)` 執行寫入
- 色彩方案透過 `@AppStorage("appColorScheme")` 控制，支援系統/淺色/深色切換
- 主題定義在 `Theme/AppTheme.swift`，品牌色為綠色系（#8BC34A / #2E7D32）
- 交易支援新增（`AddTransactionView`）與編輯（`EditTransactionView`），點擊交易列表項可編輯
- 自訂數字鍵盤 `NumberPadView` + `NumberPadLogic`（最多 7 位整數 + 2 位小數，千分位格式化）

### Services
- `AudioService`：AVAudioEngine 程式化 PCM 合成音效（無音檔），6 種音效，受 `@AppStorage("soundEffectsEnabled")` 控制
- `BackupService` / `BackupModels`：JSON 格式備份還原（Category + Account + Transaction DTO，UUID 重映射）
- `MigrationService`：一次性 App Group SQLite → CloudKit 遷移
- `WidgetDataSync` / `WidgetSnapshot`：透過 App Group `widget_snapshot.json` 與 Widget 共享資料，交易變更後自動刷新 Timeline
- `CSVExporter`：匯出交易為 CSV（自動排除 demo 資料）
- `CurrencyFormatter`：NT$ TWD 格式化，無小數
- `TimePeriodState`：週/月/年/自訂期間導航狀態管理

### Widget Extension
- 透過 App Group 讀取 `widget_snapshot.json`，支援 Small / Medium / Large 三種尺寸
- 每 15 分鐘刷新 Timeline，主 App 交易變更時也會觸發刷新
- 監聽 `NSPersistentStoreRemoteChange`（CloudKit 同步）自動更新

### 重要注意事項
- `isDefault == true` 的分類與帳戶在 UI 層禁止刪除，但 Model 層無強制保護
- 所有 UI 文字皆為繁體中文，貨幣格式為 TWD/NT$
- `@AppStorage` 鍵值：`hasCompletedOnboarding`、`appColorScheme`、`showDemoData`、`soundEffectsEnabled`
- 新增 SwiftData Model 時需在 `SchemaV3`（或新版 Schema）中註冊
