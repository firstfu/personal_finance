//
//  personal_financeUITests.swift
//  personal_financeUITests
//
//  Created by firstfu on 2026/2/17.
//

// ============================================================================
// MARK: - personal_financeUITests.swift
// 模組：UITests
//
// 功能說明：
//   這個檔案包含應用程式的 UI 自動化測試，使用 XCTest 框架
//   驗證應用程式的使用者介面行為與啟動效能。
//
// 主要職責：
//   - setUpWithError / tearDownWithError：測試前後的環境準備與清理
//   - testExample：基本 UI 測試範本，啟動應用程式並驗證介面
//   - testLaunchPerformance：測量應用程式啟動時間效能指標
//
// 注意事項：
//   - continueAfterFailure 設為 false，測試失敗時立即停止
//   - 使用 XCUIApplication 進行 UI 自動化操作
//   - 目前為 Xcode 預設模板，可根據需求擴充測試案例
// ============================================================================

import XCTest

final class personal_financeUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
