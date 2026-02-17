//
//  Color+Hex.swift
//  personal_finance
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - Color+Hex.swift
// 模組：Theme
//
// 功能說明：
//   這個檔案為 SwiftUI 的 Color 型別新增 Hex 色碼初始化擴展，
//   讓開發者可以直接使用十六進位字串（如 "#FF9800"）來建立顏色。
//
// 主要職責：
//   - 提供 Color(hex:) 便利初始化方法
//   - 支援帶有或不帶有 "#" 前綴的 Hex 色碼字串
//   - 將六位十六進位色碼解析為 RGB 分量並建立 Color 實例
//
// 注意事項：
//   - 僅支援六位 Hex 色碼（RGB），不支援八位（RGBA）透明度格式
//   - 整個專案與 Widget 模組皆依賴此擴展來解析色彩
// ============================================================================

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
