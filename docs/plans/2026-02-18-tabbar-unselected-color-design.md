# Tab Bar 未選擇項目顏色修復

## 問題

iOS 26 的 Liquid Glass 浮動 tab bar 會忽略 `UITabBar.appearance().unselectedItemTintColor` 和 `UITabBarAppearance` 的未選擇項目顏色設定。導致未選擇的 tab item 顯示為深色（近乎黑色），而非預期的灰色。

## 根本原因

Liquid Glass 設計系統刻意接管未選擇項目的樣式，根據背後內容自動調整對比度。`UITabBarAppearance` 的 `normal.iconColor` 和 `normal.titleTextAttributes` 在 Liquid Glass 啟用時被忽略。

## 方案

**停用 Liquid Glass，改用不透明背景。**

在 `ContentView.init()` 中使用 `configureWithOpaqueBackground()` 讓 tab bar 回到 iOS 18 經典風格，使 `unselectedItemTintColor` 設定生效。

### 修改

檔案：`personal_finance/ContentView.swift`

```swift
init() {
    let appearance = UITabBarAppearance()
    appearance.configureWithOpaqueBackground()
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
    UITabBar.appearance().unselectedItemTintColor = .systemGray
}
```

### 取捨

- 失去 iOS 26 Liquid Glass 浮動效果
- Tab bar 改為不透明背景（經典風格）
- 完全控制選擇/未選擇項目顏色

### 預期結果

- 選擇的 tab item：綠色（AppTheme.primaryDark, #2E7D32）
- 未選擇的 tab item：系統灰色（.systemGray）
