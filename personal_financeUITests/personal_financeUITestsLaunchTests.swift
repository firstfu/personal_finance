//
//  personal_financeUITestsLaunchTests.swift
//  personal_financeUITests
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - personal_financeUITestsLaunchTests.swift
// 模組：UITests
//
// 功能說明：
//   這個檔案定義了應用程式的啟動截圖測試，針對每一種目標裝置的
//   UI 配置（如不同螢幕尺寸、深淺色模式）自動執行啟動並擷取截圖。
//
// 主要職責：
//   - runsForEachTargetApplicationUIConfiguration：設定為 true，
//     確保測試會針對所有 UI 配置組合分別執行
//   - testLaunch：啟動應用程式並擷取啟動畫面截圖，
//     附加為測試附件以供檢視
//
// 注意事項：
//   - 截圖附件的 lifetime 設為 .keepAlways，不會被自動清理
//   - 可在 app.launch() 後加入額外步驟（如登入、導航）再擷取截圖
//   - 目前為 Xcode 預設模板，可根據需求自訂截圖時機
// ============================================================================

import XCTest

final class personal_financeUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
