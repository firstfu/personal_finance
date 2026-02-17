# 餘額調整功能實作計畫

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 讓使用者在帳戶編輯頁調整帳戶餘額到實際數字，系統自動建立 adjustment 交易記錄差額。

**Architecture:** 在 TransactionType 新增 `.adjustment` case，Account.currentBalance 計算加入 adjustment 差額。UI 入口在 AccountFormView 編輯模式，彈出 BalanceAdjustmentView sheet 讓使用者輸入實際餘額。

**Tech Stack:** Swift, SwiftUI, SwiftData

---

### Task 1: TransactionType 新增 .adjustment

**Files:**
- Modify: `personal_finance/Models/TransactionType.swift:34-46`

**Step 1: 加入 adjustment case 與 displayName**

```swift
enum TransactionType: String, Codable, CaseIterable {
    case income
    case expense
    case transfer
    case adjustment

    var displayName: String {
        switch self {
        case .income: "收入"
        case .expense: "支出"
        case .transfer: "轉帳"
        case .adjustment: "餘額調整"
        }
    }
}
```

**Step 2: 建置確認編譯通過**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: 編譯失敗，因為所有 `switch transaction.type` 缺少 `.adjustment` case。這是預期的，Task 2-4 會逐一修復。

**Step 3: Commit**

```bash
git add personal_finance/Models/TransactionType.swift
git commit -m "feat: add .adjustment case to TransactionType"
```

---

### Task 2: 修復 TransactionRow switch 完整性

**Files:**
- Modify: `personal_finance/Views/Components/TransactionRow.swift:110-127`

**Step 1: 新增 isAdjustment 判斷**

在 `TransactionRow` 中，找到 `isTransfer` 屬性（第 49 行），在其下方加入：

```swift
private var isAdjustment: Bool {
    transaction.type == .adjustment
}
```

**Step 2: 更新 body 中的圖示與文字**

將 body 中的圖示和文字邏輯改為三態判斷。找到 `Circle()` 和 `Image(systemName:)` 那段（第 56-61 行），改為：

```swift
Circle()
    .fill((isTransfer || isAdjustment ? AppTheme.primary : categoryColor).opacity(0.15))
    .frame(width: 40, height: 40)
Image(systemName: isAdjustment ? "plusminus" : (isTransfer ? "arrow.left.arrow.right" : (transaction.category?.icon ?? "questionmark.circle")))
    .foregroundStyle(isTransfer || isAdjustment ? AppTheme.primary : categoryColor)
```

找到分類名稱 Text（第 64 行），改為：

```swift
Text(isAdjustment ? "餘額調整" : (isTransfer ? "轉帳" : (transaction.category?.name ?? "未分類")))
```

找到備註顯示區塊（第 67-77 行），改為：

```swift
if isAdjustment {
    if !transaction.note.isEmpty {
        Text(transaction.note)
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
            .lineLimit(1)
    }
} else if isTransfer {
    Text(transferSubtitle)
        .font(.caption)
        .foregroundStyle(AppTheme.secondaryText)
        .lineLimit(1)
} else if !transaction.note.isEmpty {
    Text(transaction.note)
        .font(.caption)
        .foregroundStyle(AppTheme.secondaryText)
        .lineLimit(1)
}
```

找到帳戶名稱行（第 89-93 行），改條件：

```swift
if !isTransfer && !isAdjustment, let accountName = transaction.account?.name {
```

**Step 3: 更新 amountColor switch**

找到 `amountColor`（第 110-116 行），加入 adjustment case：

```swift
private var amountColor: Color {
    switch transaction.type {
    case .income: AppTheme.income
    case .expense: AppTheme.expense
    case .transfer: AppTheme.primary
    case .adjustment: AppTheme.primary
    }
}
```

**Step 4: 更新 amountText switch**

找到 `amountText`（第 118-127 行），加入 adjustment case：

```swift
private var amountText: String {
    switch transaction.type {
    case .income:
        return "+" + CurrencyFormatter.format(transaction.amount)
    case .expense:
        return "-" + CurrencyFormatter.format(transaction.amount)
    case .transfer:
        return CurrencyFormatter.format(transaction.amount)
    case .adjustment:
        let prefix = transaction.amount >= 0 ? "+" : ""
        return prefix + CurrencyFormatter.format(transaction.amount)
    }
}
```

注意：adjustment 的 amount 可正可負，所以需要判斷正負來加前綴。負數的 `CurrencyFormatter.format` 會自動帶負號。

**Step 5: Commit**

```bash
git add personal_finance/Views/Components/TransactionRow.swift
git commit -m "feat: handle .adjustment display in TransactionRow"
```

---

### Task 3: 修復 AllTransactionsView switch 完整性

**Files:**
- Modify: `personal_finance/Views/AllTransactionsView.swift:194-199, 214`

**Step 1: 更新 sectionHeader 中的 dayTotal 計算**

找到 `sectionHeader` 函式中的 switch（約第 195-199 行），加入 adjustment case：

```swift
let dayTotal = transactions.reduce(Decimal.zero) { result, tx in
    switch tx.type {
    case .income: result + tx.amount
    case .expense: result - tx.amount
    case .transfer: result
    case .adjustment: result + tx.amount
    }
}
```

**Step 2: 在篩選選單加入 adjustment 選項**

找到 `filterMenu` 中的 `ForEach`（約第 214 行），把 adjustment 加入陣列：

```swift
ForEach([TransactionType.expense, .income, .transfer, .adjustment], id: \.self) { type in
```

**Step 3: Commit**

```bash
git add personal_finance/Views/AllTransactionsView.swift
git commit -m "feat: handle .adjustment in AllTransactionsView"
```

---

### Task 4: 修復其他 switch 編譯錯誤

**Files:**
- Modify: `personal_finance/Views/AddTransactionView.swift` (typeColor switch)
- Modify: `personal_finance/Views/EditTransactionView.swift` (typeColor switch)

**Step 1: AddTransactionView — typeColor**

找到 `typeColor` 的 switch，加入：

```swift
case .adjustment: AppTheme.primary
```

注意：AddTransactionView 的 Picker 不需要加 .adjustment 選項，使用者不應手動建立 adjustment 交易。

**Step 2: EditTransactionView — typeColor**

同上，找到 `typeColor` 的 switch，加入：

```swift
case .adjustment: AppTheme.primary
```

**Step 3: 建置確認所有編譯錯誤已修復**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add personal_finance/Views/AddTransactionView.swift personal_finance/Views/EditTransactionView.swift
git commit -m "feat: add .adjustment to remaining switch statements"
```

---

### Task 5: Account.currentBalance 加入 adjustment 計算

**Files:**
- Modify: `personal_finance/Models/Account.swift:90-104`

**Step 1: 更新 currentBalance**

找到 `currentBalance` 計算屬性（第 90-104 行），在 `transferOutTotal` 之後加入 adjustmentTotal，修改 return：

```swift
var currentBalance: Decimal {
    let allTransactions = transactions ?? []
    let incomeTotal = allTransactions
        .filter { $0.type == .income }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let expenseTotal = allTransactions
        .filter { $0.type == .expense }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let transferOutTotal = allTransactions
        .filter { $0.type == .transfer }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let transferInTotal = (transferInTransactions ?? [])
        .reduce(Decimal.zero) { $0 + $1.amount }
    let adjustmentTotal = allTransactions
        .filter { $0.type == .adjustment }
        .reduce(Decimal.zero) { $0 + $1.amount }
    return initialBalance + incomeTotal - expenseTotal - transferOutTotal + transferInTotal + adjustmentTotal
}
```

**Step 2: 更新 demoBalance（同樣邏輯）**

找到 `demoBalance`（第 73-88 行），同樣加入 adjustment 計算：

```swift
var demoBalance: Decimal {
    let demoTransactions = (transactions ?? []).filter { $0.isDemoData }
    let incomeTotal = demoTransactions
        .filter { $0.type == .income }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let expenseTotal = demoTransactions
        .filter { $0.type == .expense }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let transferOutTotal = demoTransactions
        .filter { $0.type == .transfer }
        .reduce(Decimal.zero) { $0 + $1.amount }
    let demoTransferIn = (transferInTransactions ?? []).filter { $0.isDemoData }
    let transferInTotal = demoTransferIn
        .reduce(Decimal.zero) { $0 + $1.amount }
    let adjustmentTotal = demoTransactions
        .filter { $0.type == .adjustment }
        .reduce(Decimal.zero) { $0 + $1.amount }
    return incomeTotal - expenseTotal - transferOutTotal + transferInTotal + adjustmentTotal
}
```

**Step 3: 建置確認**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add personal_finance/Models/Account.swift
git commit -m "feat: include adjustment transactions in balance calculation"
```

---

### Task 6: 建立 BalanceAdjustmentView

**Files:**
- Create: `personal_finance/Views/BalanceAdjustmentView.swift`

**Step 1: 建立調整餘額 Sheet 視圖**

```swift
import SwiftUI
import SwiftData

struct BalanceAdjustmentView: View {
    let account: Account
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var actualBalanceText = ""
    @State private var note = ""

    private var currentBalance: Decimal {
        account.currentBalance
    }

    private var actualBalance: Decimal? {
        Decimal(string: actualBalanceText)
    }

    private var difference: Decimal? {
        guard let actual = actualBalance else { return nil }
        return actual - currentBalance
    }

    private var canSave: Bool {
        guard let diff = difference else { return false }
        return diff != 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("目前餘額") {
                    Text(CurrencyFormatter.format(currentBalance))
                        .font(.title2.bold())
                        .foregroundStyle(currentBalance >= 0 ? AppTheme.income : AppTheme.expense)
                }

                Section("實際餘額") {
                    TextField("輸入實際餘額", text: $actualBalanceText)
                        .keyboardType(.decimalPad)
                }

                if let diff = difference, diff != 0 {
                    Section("差額") {
                        let prefix = diff > 0 ? "+" : ""
                        Text(prefix + CurrencyFormatter.format(diff))
                            .font(.title3.bold())
                            .foregroundStyle(diff > 0 ? AppTheme.income : AppTheme.expense)
                    }
                }

                Section("備註（選填）") {
                    TextField("例如：忘記記帳的消費", text: $note)
                }
            }
            .navigationTitle("調整餘額")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("確認調整") {
                        saveAdjustment()
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveAdjustment() {
        guard let diff = difference, diff != 0 else { return }
        let transaction = Transaction(
            amount: diff,
            type: .adjustment,
            account: account,
            note: note.isEmpty ? "餘額調整" : note
        )
        modelContext.insert(transaction)
    }
}
```

**Step 2: 建置確認**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Views/BalanceAdjustmentView.swift
git commit -m "feat: add BalanceAdjustmentView for balance correction"
```

---

### Task 7: AccountFormView 加入調整餘額入口

**Files:**
- Modify: `personal_finance/Views/AccountFormView.swift`

**Step 1: 加入 sheet state**

在 AccountFormView 的 `@State` 區塊（第 62-66 行之後）加入：

```swift
@State private var showBalanceAdjustment = false
```

**Step 2: 在編輯模式的 Form 中加入目前餘額與調整按鈕**

找到 `Section("初始餘額")` 區塊（第 88-91 行），在其**之後**插入新 Section（僅編輯模式顯示）：

```swift
if case .edit(let account) = mode {
    Section("目前餘額") {
        HStack {
            Text(CurrencyFormatter.format(account.currentBalance))
                .font(.title3.bold())
                .foregroundStyle(account.currentBalance >= 0 ? AppTheme.income : AppTheme.expense)
            Spacer()
            Button("調整餘額") {
                showBalanceAdjustment = true
            }
            .font(.callout)
        }
    }
}
```

**Step 3: 加入 sheet modifier**

在 `.onAppear` 修飾器之後（第 137 行之後），加入：

```swift
.sheet(isPresented: $showBalanceAdjustment) {
    if case .edit(let account) = mode {
        BalanceAdjustmentView(account: account)
    }
}
```

**Step 4: 建置確認**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add personal_finance/Views/AccountFormView.swift
git commit -m "feat: add balance adjustment entry point in AccountFormView"
```

---

### Task 8: AnalyticsView 排除 adjustment

**Files:**
- Modify: `personal_finance/Views/AnalyticsView.swift`

**Step 1: 確認 expenses 和 incomes 過濾**

檢查 AnalyticsView 中的 `expenses` 和 `incomes` computed properties。它們已經用 `.filter { $0.type == .expense }` 和 `.filter { $0.type == .income }` 過濾，所以 `.adjustment` 類型的交易天然不會被包含。

**不需要修改** — AnalyticsView 只取 `.expense` 和 `.income`，adjustment 自動排除。

**Step 2: 確認 HomeView 月度摘要**

同理，HomeView 的 `monthlyExpense` 和 `monthlyIncome` 也是用 `.filter { $0.type == .expense/income }` 過濾的，adjustment 自動排除。

**不需要修改**。

**Step 3: 驗證建置**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -5`

Expected: BUILD SUCCEEDED

**Step 4: Commit（如有任何修改）**

如果確認不需要修改，跳過此 commit。

---

### Task 9: 完整建置與測試驗證

**Step 1: 完整建置**

Run: `xcodebuild -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build 2>&1 | tail -10`

Expected: BUILD SUCCEEDED

**Step 2: 執行單元測試**

Run: `xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' -only-testing:personal_financeTests 2>&1 | tail -10`

Expected: 全部通過（或無現有測試）

**Step 3: 執行 UI 測試**

Run: `xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' -only-testing:personal_financeUITests 2>&1 | tail -10`

Expected: 全部通過
