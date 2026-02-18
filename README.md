# 個人記帳 Personal Finance

一款使用 Swift + SwiftUI + SwiftData 打造的 iOS/iPadOS 個人記帳應用程式，介面完全採用繁體中文，支援 iCloud 同步與桌面小工具。

## 功能特色

### 記帳核心

- **四種交易類型**：支出、收入、帳戶間轉帳、餘額調整
- **豐富預設分類**：36 種支出 + 14 種收入分類，附帶圖示與色彩
- **多帳戶管理**：現金、銀行、信用卡、電子錢包，支援自訂新增
- **自訂數字鍵盤**：最多 7 位整數 + 2 位小數，千分位格式化顯示
- **高精度金額**：以 `Decimal` 型別儲存，避免浮點數誤差

### 數據分析

- **週 / 月 / 年 / 自訂**期間切換瀏覽
- **趨勢折線圖**：支出、收入、總資產三條線可獨立開關
- **分類圓餅圖**：支出與收入各自以圓餅圖呈現比例
- **互動式圖表**：點擊數據點顯示詳細數值

### 豆芽養成

透過記帳培育虛擬豆芽，增添記帳趣味：

- **五階段成長**：種子 → 發芽 → 小苗 → 茂盛 → 開花結果
- **成長機制**：每筆記帳 +3 點，連續天數額外加分（最多 +5）
- **SpriteKit 2.5D 動畫**：視差背景、貝茲曲線植物、粒子特效
- **收成圖鑑**：收成後可在圖鑑中回顧歷次成果

### 桌面小工具 (Widget)

- 支援 **Small / Medium / Large** 三種尺寸
- 顯示月度收支摘要、近期交易、帳戶餘額
- 每 15 分鐘自動刷新，交易變更時即時更新

### 資料同步與備份

- **iCloud 同步**：透過 CloudKit 私人資料庫跨裝置同步
- **JSON 備份還原**：手動匯出/匯入完整資料，可透過 AirDrop 或 iCloud Drive 分享
- **CSV 匯出**：將交易紀錄匯出為 CSV 檔案

### 其他功能

- **深色模式**：支援系統 / 淺色 / 深色三種模式切換
- **音效回饋**：6 種程式化合成音效（PCM，無音檔依賴），可在設定中開關
- **引導頁面**：首次啟動展示動畫引導頁
- **示範資料**：內建 Demo 模式方便體驗

## 技術架構

### 開發環境

| 項目 | 說明 |
|------|------|
| 語言 | Swift |
| UI 框架 | SwiftUI |
| 資料持久化 | SwiftData + CloudKit |
| 圖表 | Swift Charts |
| 動畫引擎 | SpriteKit（豆芽養成） |
| 音訊 | AVFoundation（AVAudioEngine PCM 合成） |
| 部署目標 | iOS 26.2 |
| 外部依賴 | 無（100% Apple 原生框架） |

### 專案結構

```
personal_finance/
├── personal_financeApp.swift       # App 入口，建立 ModelContainer
├── ContentView.swift               # 根視圖，TabView 五頁籤導航
├── Models/
│   ├── Transaction.swift           # 交易模型（核心）
│   ├── Category.swift              # 分類模型
│   ├── Account.swift               # 帳戶模型（含動態餘額計算）
│   ├── SproutPlant.swift           # 豆芽模型
│   ├── HarvestRecord.swift         # 收成紀錄模型
│   ├── DefaultCategories.swift     # 預設分類與帳戶種子資料
│   └── SchemaVersioning.swift      # SwiftData Schema V1→V2→V3
├── Views/
│   ├── HomeView.swift              # 首頁：摘要 + 近期交易
│   ├── AddTransactionView.swift    # 記帳：新增交易
│   ├── EditTransactionView.swift   # 編輯交易
│   ├── SproutTabView.swift         # 豆芽養成頁
│   ├── AnalyticsView.swift         # 分析：圖表與統計
│   ├── SettingsView.swift          # 設定頁
│   ├── OnboardingView.swift        # 首次啟動引導
│   └── Components/                 # 共用元件
│       ├── NumberPadView.swift     # 自訂數字鍵盤
│       ├── MonthlySummaryCard.swift
│       ├── TransactionRow.swift
│       └── PeriodNavigationBar.swift
├── Services/
│   ├── AudioService.swift          # 音效合成服務
│   ├── BackupService.swift         # JSON 備份還原
│   ├── SproutGrowthService.swift   # 豆芽成長邏輯
│   ├── WidgetDataSync.swift        # Widget 資料同步
│   └── CSVExporter.swift           # CSV 匯出
├── SpriteKit/                      # 豆芽 2.5D 動畫場景
│   ├── SproutScene.swift
│   ├── PlantNode.swift
│   ├── PotNode.swift
│   ├── GroundNode.swift
│   ├── BackgroundNode.swift
│   └── ParticleEffects.swift
├── Helpers/
│   ├── CurrencyFormatter.swift     # NT$ TWD 貨幣格式化
│   └── TimePeriodState.swift       # 期間導航狀態
└── Theme/
    └── AppTheme.swift              # 全域主題（色彩、字型、間距）

personal_finance_Widget/            # Widget Extension
├── personal_finance_Widget.swift   # Timeline Provider + Widget 入口
├── WidgetDataProvider.swift        # 讀取 App Group 共享資料
└── Views/
    ├── SmallWidgetView.swift
    ├── MediumWidgetView.swift
    └── LargeWidgetView.swift
```

### 資料模型

5 個 SwiftData Model，經歷三個 Schema 版本（皆為 lightweight migration）：

| Model | 說明 | 關鍵欄位 |
|-------|------|----------|
| `Transaction` | 交易紀錄 | amountString, type, date, category, account |
| `Category` | 分類 | name, icon, colorHex, type (收入/支出) |
| `Account` | 帳戶 | name, type, initialBalanceString, currentBalance (computed) |
| `SproutPlant` | 培育中的豆芽 | currentStage (0-4), growthPoints, consecutiveDays |
| `HarvestRecord` | 收成紀錄 | totalGrowthPoints, totalDaysNurtured, longestStreak |

**關聯關係**：
- `Transaction` → `Category`（多對一）
- `Transaction` → `Account`（多對一）
- `Transaction` → `transferToAccount`（轉帳對象，可選）

### 並行模型

- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`：所有型別預設為 `@MainActor` 隔離
- `SWIFT_APPROACHABLE_CONCURRENCY = YES`：啟用結構化並行最佳實踐

### 設計主題

| 色彩 | 色碼 | 用途 |
|------|------|------|
| Primary | `#8BC34A` | 品牌主色（綠色） |
| Primary Dark | `#2E7D32` | 品牌深色 |
| Income | `#4CAF50` | 收入色 |
| Expense | `#E53935` | 支出色 |
| Background | `#F4F5F0` | 淺色模式背景 |

## 建置與執行

### 前置需求

- Xcode 26+
- iOS 26.2 Simulator 或實機
- Apple Developer 帳號（CloudKit 功能需要）

### 建置指令

```bash
# 建置
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' build

# 執行單元測試
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:personal_financeTests

# 執行 UI 測試
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:personal_financeUITests
```

或直接在 Xcode 中開啟 `personal_finance.xcodeproj`，選擇目標裝置後按 `Cmd + R` 執行。

## App 導航結構

```
App 啟動
├── OnboardingView（首次啟動）
└── TabView
    ├── 🏠 首頁 ─── 資產總覽 / 月度摘要 / 近期交易
    ├── ✏️ 記帳 ─── 支出·收入·轉帳切換 / 數字鍵盤 / 分類選擇
    ├── 🌱 豆芽 ─── SpriteKit 動畫 / 成長進度 / 收成圖鑑
    ├── 📊 分析 ─── 趨勢圖表 / 分類圓餅圖 / 期間切換
    └── ⚙️ 設定 ─── 外觀 / 帳戶管理 / 備份還原 / 匯出
```

## 授權條款

此專案為個人開發作品，保留所有權利。
