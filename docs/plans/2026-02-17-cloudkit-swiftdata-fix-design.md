# 設計：修復 CloudKit + SwiftData 相容性

**日期**: 2026-02-17
**狀態**: 已批准

## 問題

App 啟用了 iCloud entitlements，SwiftData 嘗試以 CloudKit 模式載入 store，但 Model 不符合 CloudKit 要求：
- 所有屬性必須是 Optional 或有預設值
- 所有 Relationship 必須是 Optional

導致 `ModelContainer` 初始化時 `fatalError`。

## 方案

**方案 A：為所有屬性加預設值**（已選定）

- 改動最小，init 參數簽名不變
- 現有 View 程式碼幾乎不受影響
- Relationships 改為 Optional（`[Transaction]?`），使用處加 `?? []`

## 修改範圍

### 1. Account.swift
- 所有屬性加預設值：`name = ""`, `type = .cash`, `icon = ""`, `colorHex = "#000000"`, `initialBalance = 0`, `sortOrder = 0`, `isDefault = false`
- `transactions` 改為 `[Transaction]? = []`
- 移除 `@Relationship` 的 `inverse` 參數
- `currentBalance` 改用 `transactions ?? []`

### 2. Category.swift
- 所有屬性加預設值：`name = ""`, `icon = ""`, `colorHex = "#000000"`, `type = .expense`, `sortOrder = 0`, `isDefault = false`
- `transactions` 改為 `[Transaction]? = []`
- 移除 `@Relationship` 的 `inverse` 參數

### 3. Transaction.swift
- 所有屬性加預設值：`amount = 0`, `type = .expense`, `note = ""`, `date = .now`, `createdAt = .now`
- `category` 和 `account` 已是 Optional，不動

### 4. personal_finance.entitlements
- `com.apple.developer.icloud-services` 從 `CloudDocuments` 改為 `CloudKit`

### 5. personal_financeApp.swift
- `ModelConfiguration` 加 `cloudKitDatabase: .automatic`

### 6. View 層影響
- 所有使用 `account.transactions` 或 `category.transactions` 的地方改用 `?? []`
