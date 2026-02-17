// ============================================================================
// MARK: - AppTheme.swift
// 模組：Theme
//
// 功能說明：
//   這個檔案定義了應用程式的全域主題樣式，包含品牌色彩、語意色彩、
//   漸層效果、圓角半徑、間距以及字型等設計常數。
//
// 主要職責：
//   - 定義品牌固定色彩：primary（#8BC34A）、primaryDark（#2E7D32）、
//     income（綠色）、expense（紅色）
//   - 定義語意色彩：surface、onBackground、secondaryText（自動適配深色模式）
//   - 提供品牌漸層 primaryGradient（用於卡片與 Widget 背景）
//   - 統一管理 UI 常數：圓角半徑、水平內距、卡片間距
//   - 定義全域字型樣式：amountFont、titleFont、captionFont
//
// 注意事項：
//   - 品牌色為固定值，不隨深色模式變化
//   - 語意色彩使用 UIKit 動態色彩（如 .secondarySystemBackground），自動適配深色模式
// ============================================================================

import SwiftUI

enum AppTheme {
    // Brand colors (fixed, don't change with dark mode)
    static let primary = Color(hex: "#8BC34A")
    static let primaryDark = Color(hex: "#2E7D32")
    static let income = Color(hex: "#4CAF50")
    static let expense = Color(hex: "#E53935")

    // Semantic colors (adapt to dark mode automatically)
    static let surface = Color(.secondarySystemBackground)
    static let onBackground = Color(.label)
    static let secondaryText = Color(.secondaryLabel)

    static let primaryGradient = LinearGradient(
        colors: [primary, primaryDark],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 12
    static let horizontalPadding: CGFloat = 16
    static let cardSpacing: CGFloat = 12

    static let amountFont = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let titleFont = Font.title2.bold()
    static let captionFont = Font.caption
}
