# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS/iPadOS 個人記帳應用程式（繁體中文介面），使用 Swift + SwiftUI + SwiftData 建構。

- Bundle ID: `com.firstfu.com.personal-finance`
- Development Team: `WY468E45SJ`
- 部署目標: iOS 26.2，支援 iPhone 與 iPad
- 無外部套件依賴，僅使用 Apple 原生框架（SwiftUI、SwiftData、Charts）
- 已設定 CloudKit 與 Push Notifications entitlements（尚未實作）

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

### 資料層
- **三個 SwiftData Model**：`Transaction`、`Category`、`Account`，全部需在 schema 中註冊
- `ModelContainer` 在 `personal_financeApp.swift` 建立並注入環境
- App 啟動時透過 `DefaultCategories.seed()` 植入預設分類（8 支出 + 4 收入）與帳戶（3 個）
- 金額使用 `Decimal` 型別確保精度，僅在 Charts 渲染時轉為 `Double`
- 關聯：`Transaction -> Category`（多對一，nullify）、`Transaction -> Account`（多對一，nullify）

### UI 層
- 根視圖 `ContentView` 使用 `TabView`（首頁/記帳/分析/設定），首次啟動顯示 `OnboardingView`
- 透過 `@Query` 取得資料，`@Environment(\.modelContext)` 執行寫入
- 色彩方案透過 `@AppStorage("appColorScheme")` 控制，支援系統/淺色/深色切換
- 主題定義在 `Theme/AppTheme.swift`，品牌色為綠色系（#8BC34A / #2E7D32）

### 重要注意事項
- `isDefault == true` 的分類與帳戶在 UI 層禁止刪除，但 Model 層無強制保護
- 交易目前只能新增，無編輯或單筆刪除功能（僅有全部重置）
- 所有 UI 文字皆為繁體中文，貨幣格式為 TWD/NT$
