# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

iOS/iPadOS 個人記帳應用程式，使用 Swift + SwiftUI + SwiftData 建構，目標部署版本為 iOS 26.2。

- Bundle ID: `com.firstfu.com.personal-finance`
- Development Team: `WY468E45SJ`
- 支援裝置: iPhone 與 iPad
- 已設定 CloudKit 與 Push Notifications entitlements（尚未實作）

## Build & Test Commands

```bash
# 建置
xcodebuild -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' build

# 執行單元測試（使用 Swift Testing 框架）
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeTests

# 執行 UI 測試（使用 XCTest 框架）
xcodebuild test -project personal_finance.xcodeproj -scheme personal_finance \
  -destination 'platform=iOS Simulator,id=CDBF104B-5DB1-48C7-9E80-F483AC4A2C06' \
  -only-testing:personal_financeUITests
```

## Architecture

目前為 Xcode 模板初始狀態，尚未建立正式架構模式。

### 關鍵 Swift 設定
- `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — 所有型別預設為 `@MainActor` 隔離
- `SWIFT_APPROACHABLE_CONCURRENCY = YES` — 啟用結構化並行最佳實踐
- SwiftData 使用磁碟儲存（`isStoredInMemoryOnly: false`），Preview 中使用記憶體儲存

### 資料層
- SwiftData `ModelContainer` 在 App 入口點建立並注入 SwiftUI 環境
- 資料模型定義在 `personal_finance/Item.swift`（目前僅有 `Item` 佔位模型）

### UI 層
- 根視圖 `ContentView.swift` 使用 `NavigationSplitView` 實作主從式佈局
- 透過 `@Query` 巨集取得資料，`@Environment(\.modelContext)` 執行寫入操作
