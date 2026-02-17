//
//  AppTheme.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

import SwiftUI

enum AppTheme {
    static let primary = Color(hex: "#8BC34A")
    static let primaryDark = Color(hex: "#2E7D32")
    static let surface = Color(hex: "#F5F5F5")
    static let onBackground = Color(hex: "#1A1A1A")
    static let secondaryText = Color(hex: "#757575")
    static let income = Color(hex: "#4CAF50")
    static let expense = Color(hex: "#E53935")

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
