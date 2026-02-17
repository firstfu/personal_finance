# 首頁佈局重構 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 將首頁帳戶餘額和最近交易區塊重構為摘要卡片式佈局，縮短頁面長度並提升視覺層次。

**Architecture:** 僅修改 HomeView.swift，將 accountBalanceSection 改為按 AccountType 匯總的 3 行摘要，將 recentTransactionsSection 從 10 筆縮減為 5 筆，兩個區塊各自加上圓角卡片背景。

**Tech Stack:** Swift, SwiftUI, SwiftData

---

### Task 1: 重構 accountBalanceSection 為帳戶類型匯總

**Files:**
- Modify: `personal_finance/Views/HomeView.swift:130-171`

**Step 1: 替換 accountBalanceSection**

將現有的逐一列出所有帳戶的 `accountBalanceSection` 替換為按 `AccountType` 分組匯總的版本：

```swift
private var accountBalanceSection: some View {
    VStack(alignment: .leading, spacing: 8) {
        // Header
        HStack {
            Text("帳戶總覽")
                .font(.headline)
            Spacer()
            Button {
                // TODO: 導航到帳戶詳情頁
            } label: {
                Text("查看全部")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primary)
            }
        }

        // 按帳戶類型匯總
        ForEach(AccountType.allCases, id: \.self) { type in
            let typeAccounts = accounts.filter { $0.type == type }
            if !typeAccounts.isEmpty {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.primary.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: type.defaultIcon)
                            .font(.body)
                            .foregroundStyle(AppTheme.primary)
                    }
                    Text(type.displayName)
                        .font(.body)
                    Spacer()
                    let total = typeAccounts.reduce(Decimal.zero) { $0 + $1.currentBalance }
                    Text(CurrencyFormatter.format(total))
                        .font(.body.bold().monospacedDigit())
                        .foregroundStyle(total >= 0 ? AppTheme.onBackground : AppTheme.expense)
                }
                .padding(.vertical, 2)
            }
        }

        Divider()

        // 總淨值
        HStack {
            Text("總淨值")
                .font(.headline)
            Spacer()
            let totalNetWorth = accounts.reduce(Decimal.zero) { $0 + $1.currentBalance }
            Text(CurrencyFormatter.format(totalNetWorth))
                .font(.headline.bold().monospacedDigit())
                .foregroundStyle(totalNetWorth >= 0 ? AppTheme.income : AppTheme.expense)
        }
        .padding(.vertical, 2)
    }
    .padding()
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
}
```

**Step 2: Build 驗證**

Run:
```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build
```
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Views/HomeView.swift
git commit -m "refactor: 帳戶餘額區塊改為按類型匯總摘要 + 卡片包裝"
```

---

### Task 2: 重構 recentTransactionsSection 為 5 筆 + 卡片包裝

**Files:**
- Modify: `personal_finance/Views/HomeView.swift:173-193`

**Step 1: 替換 recentTransactionsSection**

將最近交易從 10 筆縮減為 5 筆，加上 header 中的「查看全部」按鈕和卡片包裝：

```swift
private var recentTransactionsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        // Header
        HStack {
            Text("最近交易")
                .font(.headline)
            Spacer()
            Button {
                // TODO: 導航到完整交易列表
            } label: {
                Text("查看全部")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primary)
            }
        }

        if allTransactions.isEmpty {
            Text("尚無交易紀錄")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
        } else {
            ForEach(Array(allTransactions.prefix(5).enumerated()), id: \.element.id) { index, tx in
                if index > 0 {
                    Divider()
                }
                TransactionRow(transaction: tx)
            }
        }
    }
    .padding()
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
}
```

**Step 2: Build 驗證**

Run:
```bash
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build
```
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add personal_finance/Views/HomeView.swift
git commit -m "refactor: 最近交易縮減為 5 筆 + 查看全部按鈕 + 卡片包裝"
```

---

### Task 3: 更新檔案頭部註解

**Files:**
- Modify: `personal_finance/Views/HomeView.swift:1-36`

**Step 1: 更新註解**

將檔案頂部註解中的描述更新以反映新佈局：
- 「列出所有帳戶的即時餘額」→「按帳戶類型匯總餘額」
- 「最近 10 筆交易紀錄」→「最近 5 筆交易紀錄」
- accountBalanceSection 描述更新
- recentTransactionsSection 描述更新

**Step 2: Commit**

```bash
git add personal_finance/Views/HomeView.swift
git commit -m "docs: 更新 HomeView 檔案頭部註解以反映新佈局"
```
