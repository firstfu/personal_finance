# Widget 餘額修復設計文件

**日期**: 2026-02-18
**狀態**: Approved

## 問題

Widget 的月餘額只計算「當月收入 - 當月支出」，完全忽略帳戶的初始餘額（initialBalance），導致與 App 首頁的數字不一致。

## 根因

`WidgetDataSync.swift` 第 130 行：
```swift
monthlyBalanceString: "\(monthlyIncome - monthlyExpense)",
```

## 修復方案

將 `monthlyBalanceString` 改為所有帳戶 `currentBalance` 的總和，與 App 首頁 HomeView 的 `totalBalance` 計算邏輯一致。

### 修改檔案

`personal_finance/Services/WidgetDataSync.swift`

### 修改內容

在建立 `WidgetSnapshot` 之前計算帳戶總餘額，並替換 `monthlyBalanceString` 的值：

```swift
let totalBalance = accounts.reduce(Decimal.zero) { $0 + $1.currentBalance }

let snapshot = WidgetSnapshot(
    ...
    monthlyBalanceString: "\(totalBalance)",  // 改用帳戶實際總餘額
    ...
)
```

### 不需修改的部分

- Widget Extension View 層（SmallWidgetView、MediumWidgetView、LargeWidgetView）
- WidgetSnapshot 資料模型
- WidgetDataProvider
