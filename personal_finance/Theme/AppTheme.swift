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
