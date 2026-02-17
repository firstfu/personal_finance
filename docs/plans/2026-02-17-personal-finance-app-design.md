# Personal Finance iOS App — Design Document

**Date:** 2026-02-17
**Status:** Approved

## Overview

iOS/iPadOS 個人記帳應用程式，專注於日常收支記錄與分類統計分析。使用 Swift + SwiftUI + SwiftData 建構，目標部署版本 iOS 26.2。

### Core Features

- 快速記帳（收入/支出）
- 分類管理（預設 + 自定義）
- 月度/週度統計圖表（折線圖 + 圓餅圖）
- 交易紀錄瀏覽與搜尋
- 僅支援新台幣 (TWD)

## Visual Design

### Design Reference

參照 Dribbble 設計：[Personal Finance iOS App](https://dribbble.com/shots/24622160-Personal-Finance-iOS-App)

### Color Palette

| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#8BC34A` | 萊姆綠，主強調色、按鈕高亮 |
| Primary Dark | `#2E7D32` | 深森林綠，CTA 按鈕背景 |
| Background | `#FFFFFF` | 主畫面背景 |
| Surface | `#F5F5F5` | 卡片/Section 背景 |
| On Background | `#1A1A1A` | 主要文字 |
| Secondary Text | `#757575` | 副文字、標籤 |
| Income | `#4CAF50` | 收入金額 |
| Expense | `#E53935` | 支出金額 |

### Typography

- 金額數字：`Font.system(.largeTitle, design: .rounded, weight: .bold)`
- 標題：`Font.title2.bold()`
- 內文：`Font.body`
- 標籤：`Font.caption` 灰色

### Spacing & Radius

- 卡片圓角：16pt
- 按鈕圓角：12pt
- 頁面水平 padding：16pt
- 卡片間距：12pt

## Navigation Architecture

底部 4 Tab 架構：

```
TabView
├── Tab 1: 首頁 (house.fill)
├── Tab 2: 記帳 (plus.circle.fill)
├── Tab 3: 分析 (chart.bar.fill)
└── Tab 4: 設定 (gearshape.fill)
```

## Screen Designs

### 1. HomeView — 首頁

```
NavigationStack
├── 頂部問候區
│   ├── "嗨，使用者" + 日期
│   └── 通知鈴鐺圖標
├── 本月摘要卡片（萊姆綠漸層背景）
│   ├── "本月餘額" 大字金額
│   ├── 收入小計（綠色 ↑）
│   └── 支出小計（紅色 ↓）
├── 快速記帳按鈕列
│   ├── "+ 支出" 按鈕（深綠色實心）
│   └── "+ 收入" 按鈕（綠色描邊）
└── 最近交易列表
    └── 每筆：圖標 | 分類名稱 | 備註 | 金額 | 時間
```

### 2. AddTransactionView — 記帳頁

```
全螢幕記帳介面
├── 頂部：收入/支出 Segmented Picker
├── 金額輸入區（大字顯示，類似計算機）
├── 分類選擇 Grid（2列圖標格）
│   └── 飲食🍽️ 交通🚗 娛樂🎬 購物🛍️
│       居住🏠 醫療💊 教育📚 其他📌
├── 日期選擇器（預設今天）
├── 備註輸入框（可選）
└── 儲存按鈕
```

### 3. AnalyticsView — 分析頁

```
ScrollView
├── 時間篩選器（本週/本月/本年）
├── 消費趨勢卡片
│   ├── 總支出金額 + 與上期比較百分比
│   └── 折線圖（Swift Charts）
├── 分類比例卡片
│   ├── 圓餅圖（Swift Charts）
│   └── 分類排行列表
│       └── 每項：彩色圓點 | 分類名 | 金額 | 百分比
└── （未來可擴展：月對月比較等）
```

### 4. SettingsView — 設定頁

```
List (Grouped)
├── Section: 分類管理
│   └── 新增/編輯/刪除/排序分類
├── Section: 資料
│   └── 匯出 CSV（未來）
└── Section: 關於
    └── 版本資訊
```

## Data Models

### Transaction

```swift
@Model
final class Transaction {
    var amount: Decimal
    var type: TransactionType    // .income | .expense
    var category: Category?
    var note: String
    var date: Date
    var createdAt: Date
}

enum TransactionType: String, Codable {
    case income
    case expense
}
```

### Category

```swift
@Model
final class Category {
    var name: String
    var icon: String             // SF Symbol name
    var colorHex: String
    var type: TransactionType
    var sortOrder: Int
    var isDefault: Bool

    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]
}
```

### Default Categories

**Expense:**

| Name | Icon | Color |
|------|------|-------|
| 飲食 | fork.knife | #FF9800 |
| 交通 | car.fill | #2196F3 |
| 娛樂 | gamecontroller.fill | #9C27B0 |
| 購物 | bag.fill | #E91E63 |
| 居住 | house.fill | #795548 |
| 醫療 | cross.case.fill | #F44336 |
| 教育 | book.fill | #3F51B5 |
| 其他 | ellipsis.circle.fill | #607D8B |

**Income:**

| Name | Icon | Color |
|------|------|-------|
| 薪資 | briefcase.fill | #4CAF50 |
| 獎金 | star.fill | #FFC107 |
| 投資 | chart.line.uptrend.xyaxis | #00BCD4 |
| 其他 | ellipsis.circle.fill | #8BC34A |

## Technical Stack

- **UI Framework:** SwiftUI (iOS 26.2)
- **Data:** SwiftData with disk persistence
- **Charts:** Swift Charts framework
- **Concurrency:** MainActor default isolation, structured concurrency
- **Architecture:** MVVM-light (SwiftUI @Query + @Observable ViewModels where needed)
- **Future:** CloudKit sync (entitlements already configured)
