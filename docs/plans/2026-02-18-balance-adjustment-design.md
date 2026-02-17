# 餘額調整功能設計

## 概述

當帳戶實際金額與 App 記錄不符時，使用者可在帳戶編輯頁調整餘額到正確數字。系統自動建立一筆「餘額調整」交易記錄差額，保持帳務歷史完整可追溯。

## 資料模型

### TransactionType 新增 `.adjustment`

```swift
enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense
    case transfer
    case adjustment  // 新增：餘額調整
}
```

### adjustment 交易特性

- `amount`：差額（實際餘額 - 目前餘額），正數表示餘額增加，負數表示減少
- `account`：被調整的帳戶
- `category`：nil（adjustment 不需要分類）
- `note`：使用者選填備註
- `date`：調整當下的時間

### currentBalance 計算更新

```swift
var currentBalance: Decimal {
    let adjustmentTotal = allTransactions
        .filter { $0.type == .adjustment }
        .reduce(.zero) { $0 + $1.amount }

    return initialBalance + incomeTotal - expenseTotal
           - transferOutTotal + transferInTotal + adjustmentTotal
}
```

## UI 設計

### 入口：AccountFormView 編輯模式

在帳戶編輯頁面中：
1. 顯示「目前餘額：NT$ XX,XXX」（唯讀）
2. 下方放置「調整餘額」按鈕

### 調整餘額 Sheet

點擊按鈕後彈出 `.sheet`，包含：
- 目前餘額（唯讀顯示）
- 「實際餘額」輸入框（數字鍵盤）
- 自動計算並顯示差額（例如「差額：+500」或「差額：-300」）
- 備註欄位（選填）
- 確認按鈕（差額為 0 時禁用）

### 交易列表顯示

adjustment 交易在列表中以特殊樣式呈現：
- 顯示「餘額調整」標籤
- 金額顯示差額（+/- 方向）

## 報表處理

- adjustment 交易**不計入**收入/支出統計
- 在分析頁面的收支圖表中排除 adjustment 類型
- 交易列表中可見但有明確標記

## 影響範圍

### 需修改的檔案
- `Models/Transaction.swift` — TransactionType 新增 .adjustment
- `Models/Account.swift` — currentBalance 計算加入 adjustment
- `Views/AccountFormView.swift` — 編輯模式加入餘額顯示與調整按鈕
- 新增 `Views/BalanceAdjustmentView.swift` — 調整餘額 Sheet
- `Views/HomeView.swift` — 交易列表中 adjustment 的顯示樣式
- `Views/AnalyticsView.swift` — 報表過濾排除 adjustment

### 不影響的部分
- 初始餘額不變
- 現有交易不受影響
- 帳戶新增流程不變
