# 總資產顯示修正與分析頁增強 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 修正首頁總資產計算（過濾 demo 交易），在分析頁新增總資產欄位，並將趨勢圖的「淨額」線替換為「總資產」線。

**Architecture:** 在 Model 層修正 `Account.currentBalance` 過濾 demo 交易，然後在 AnalyticsView 加入 accounts query 並更新 UI（摘要卡片 + 趨勢圖）。

**Tech Stack:** Swift, SwiftUI, SwiftData, Charts

---

### Task 1: 修正 Account.currentBalance 過濾 demo 交易

**Files:**
- Modify: `personal_finance/Models/Account.swift:93-110`

**Step 1: 修改 currentBalance 過濾 isDemoData**

在 `currentBalance` 中，將 `let allTransactions = transactions ?? []` 改為過濾掉 demo 交易：

```swift
var currentBalance: Decimal {
    let allTransactions = (transactions ?? []).filter { !$0.isDemoData }
    let incomeTotal = allTransactions
        .filter { $0.type == .income }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let expenseTotal = allTransactions
        .filter { $0.type == .expense }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let transferOutTotal = allTransactions
        .filter { $0.type == .transfer }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let transferInTotal = (transferInTransactions ?? []).filter { !$0.isDemoData }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let adjustmentTotal = allTransactions
        .filter { $0.type == .adjustment }
        .reduce(Decimal.zero) { $0 + $1.amount }
    return initialBalance + incomeTotal - expenseTotal - transferOutTotal + transferInTotal + adjustmentTotal
}
```

**Step 2: 建置驗證**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Models/Account.swift
git commit -m "fix: filter demo transactions from Account.currentBalance"
```

---

### Task 2: 分析頁摘要卡片新增「總資產」

**Files:**
- Modify: `personal_finance/Views/AnalyticsView.swift:49-51` (加 @Query)
- Modify: `personal_finance/Views/AnalyticsView.swift:103-143` (更新 spendingSummaryCard)

**Step 1: 加入 accounts query 與 totalBalance computed property**

在 AnalyticsView 的 properties 區（第 51 行 `@AppStorage` 之後）加入：

```swift
@Query(sort: \Account.sortOrder) private var accounts: [Account]
```

在 `totalIncome` computed property 之後加入：

```swift
private var totalBalance: Decimal {
    accounts.reduce(Decimal.zero) { $0 + (showDemoData ? $1.demoBalance : $1.currentBalance) }
}
```

**Step 2: 更新 spendingSummaryCard 加入總資產欄位**

在 `spendingSummaryCard` 的淨額 VStack 之後、`.frame(maxWidth: .infinity)` 之前，加入：

```swift
Divider()

VStack(spacing: 4) {
    Text("總資產")
        .font(AppTheme.captionFont)
        .foregroundStyle(AppTheme.secondaryText)
    Text(CurrencyFormatter.format(totalBalance))
        .font(AppTheme.amountFont)
        .foregroundStyle(totalBalance >= 0 ? AppTheme.income : AppTheme.expense)
}
```

**Step 3: 建置驗證**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add personal_finance/Views/AnalyticsView.swift
git commit -m "feat: add total asset display to analytics summary card"
```

---

### Task 3: 趨勢圖「淨額」→「總資產」

**Files:**
- Modify: `personal_finance/Views/AnalyticsView.swift`

需修改以下位置：

**Step 1: 重命名 state variable**

將第 59 行 `showNetLine` 改為 `showAssetLine`：

```swift
@State private var showAssetLine: Bool = false
```

**Step 2: 更新趨勢圖中的 showNetLine → showAssetLine**

所有 `showNetLine` 引用改為 `showAssetLine`，包含：
- 第 198 行: `if showAssetLine {`
- 第 203 行: series value `"總資產"`
- 第 214 行: `let matchedAsset = showAssetLine ? dailyAsset.first(...)`
- 第 215 行: `matchedAsset?.date`
- 第 234-238 行: annotation 文字改為「總資產」

**Step 3: 更新 dailyNet → dailyAsset 計算邏輯**

將 `dailyNet` 替換為 `dailyAsset`，計算每天的總資產（= 帳戶初始餘額加總 + 累計淨收支）：

```swift
private var baseBalance: Double {
    let total = accounts.reduce(Decimal.zero) { $0 + $1.initialBalance }
    return NSDecimalNumber(decimal: total).doubleValue
}

private var dailyAsset: [(date: Date, total: Double)] {
    let calendar = Calendar.current
    let allDates = Set(
        (expenses + incomes).map { calendar.startOfDay(for: $0.date) }
    )
    let expenseByDay = Dictionary(grouping: expenses) { calendar.startOfDay(for: $0.date) }
    let incomeByDay = Dictionary(grouping: incomes) { calendar.startOfDay(for: $0.date) }
    let daily = allDates.map { date in
        let inc = incomeByDay[date]?.reduce(Decimal.zero) { $0 + $1.amount } ?? .zero
        let exp = expenseByDay[date]?.reduce(Decimal.zero) { $0 + $1.amount } ?? .zero
        return (date: date, total: NSDecimalNumber(decimal: inc - exp).doubleValue)
    }
    .sorted { $0.date < $1.date }
    var cumulative: Double = baseBalance
    return daily.map { item in
        cumulative += item.total
        return (date: item.date, total: cumulative)
    }
}
```

**Step 4: 更新篩選器膠囊標籤**

第 279 行，將 `"淨額"` 改為 `"總資產"`：

```swift
trendFilterChip(label: "總資產", color: AppTheme.primary, isOn: $showAssetLine)
```

**Step 5: 更新 activeLineCount、activeTrendDomain、activeTrendRange**

- `activeLineCount`: `showNetLine` → `showAssetLine`
- `activeTrendDomain`: `"淨額"` → `"總資產"`
- `activeTrendRange`: `showNetLine` → `showAssetLine`

**Step 6: 建置驗證**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build`
Expected: BUILD SUCCEEDED

**Step 7: Commit**

```bash
git add personal_finance/Views/AnalyticsView.swift
git commit -m "feat: replace net amount trend line with total asset trend line"
```
