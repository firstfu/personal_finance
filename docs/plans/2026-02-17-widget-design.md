# Widget 桌面小工具設計文件

**版本**: v2.0 Feature
**狀態**: Approved
**日期**: 2026-02-17

## 概述

為個人記帳 App 新增 iOS 桌面小工具（WidgetKit），提供三種尺寸的美觀財務摘要，讓用戶無需打開 App 即可查看本月收支狀態。

## 需求摘要

- 支援 Small、Medium、Large 三種 Widget 尺寸
- 延續 App 的萊姆綠漸層視覺風格
- 點擊 Widget 打開 App 首頁（無互動按鈕）
- App 內交易變更時即時更新 Widget
- 支援暗色模式

## 架構：App Group + SwiftData 共享

### 資料共享

```
主 App (讀寫) ──── App Group 共享目錄 ──── Widget Extension (唯讀)
                    └── default.store (SwiftData)
```

- App Group ID: `group.com.firstfu.personal-finance`
- `ModelContainer` 使用 `ModelConfiguration(url: appGroupURL)` 儲存到共享目錄
- Widget Extension 建立自己的 `ModelContainer` 指向同一資料庫，僅做查詢
- 共享 Model 檔案需同時加入主 App 和 Widget Extension 兩個 target

### 更新機制

- 主 App 每次交易儲存/刪除/重置後呼叫 `WidgetCenter.shared.reloadAllTimelines()`
- Widget Timeline Provider 設定 15 分鐘自動刷新作為備援

## Widget 內容規劃

### Small Widget (systemSmall)

顯示本月餘額（大字 Bold）、收入和支出小字。
背景為萊姆綠到深綠漸層。

### Medium Widget (systemMedium)

上半部：本月餘額、收入、支出摘要。
下半部：前 3 名支出分類及佔比（分類 icon + 百分比）。
背景同漸層風格。

### Large Widget (systemLarge)

上方：月收支摘要卡。
中間：最近 5 筆交易（分類 icon、備註、金額）。
底部：帳戶餘額總覽。
上方漸層 + 下方跟隨系統配色。

## 技術細節

### 檔案結構

```
personal_finance/
├── Shared/                          # App 和 Widget 共享的程式碼
│   ├── Models/                      # 搬移現有 Models
│   ├── Theme/AppTheme.swift
│   ├── Theme/Color+Hex.swift
│   └── Helpers/CurrencyFormatter.swift
│
personal_finance_Widget/              # 新建 Widget Extension
├── personal_finance_Widget.swift     # Widget 定義 + Entry + Provider
├── Views/
│   ├── SmallWidgetView.swift
│   ├── MediumWidgetView.swift
│   └── LargeWidgetView.swift
├── WidgetDataProvider.swift          # SwiftData 查詢 + 計算摘要
├── Info.plist
└── Assets.xcassets/
```

### Widget Entry

```swift
struct FinanceWidgetEntry: TimelineEntry {
    let date: Date
    let monthlyIncome: Decimal
    let monthlyExpense: Decimal
    let monthlyBalance: Decimal
    let topCategories: [(name: String, icon: String, colorHex: String, percentage: Double)]
    let recentTransactions: [WidgetTransaction]
    let accounts: [(name: String, icon: String, balance: Decimal)]
    let displayMonth: String
}

struct WidgetTransaction {
    let categoryIcon: String
    let categoryName: String
    let note: String
    let amount: Decimal
    let type: TransactionType
}
```

### Timeline Provider

- `placeholder()`: 顯示假資料骨架
- `getSnapshot()`: Widget Gallery 預覽用
- `getTimeline()`: 查詢 SwiftData，建立 entry，設定 15 分鐘後刷新

### 主 App 改動

1. `personal_financeApp.swift`: `ModelConfiguration` 改用 App Group URL
2. 首次啟動處理資料庫遷移（舊位置 → App Group 目錄）
3. `AddTransactionView.swift`: 儲存後呼叫 `WidgetCenter.shared.reloadAllTimelines()`
4. `SettingsView.swift`: 刪除/重置後呼叫 reload

### Deep Link

- Widget: `widgetURL(URL(string: "personalfinance://home")!)`
- App: `.onOpenURL` 處理（導向首頁）

## 視覺風格

- 延續現有 `AppTheme` 的萊姆綠漸層（`#8BC34A` → `#2E7D32`）
- 收入綠色 `#4CAF50`、支出紅色 `#E53935`
- 圓角 16pt（與 App 卡片一致）
- 支援暗色模式：漸層保持，底部區域跟隨 `.widgetBackground`
