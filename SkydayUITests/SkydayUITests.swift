import XCTest

/// End-to-end flows. Requires macOS + Xcode + an iOS Simulator; NOT run in the Linux
/// environment this project was authored in (see QA_REPORT.md).
final class SkydayUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(reset: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting"] + (reset ? ["-resetData"] : [])
        app.launch()
        return app
    }

    func testFirstLaunchShowsEmptyStateAndThreeTabs() {
        let app = launch(reset: true)
        XCTAssertTrue(app.buttons["emptyStateAddButton"].waitForExistence(timeout: 5))
        let tabs = app.tabBars.buttons
        XCTAssertEqual(tabs.count, 3)
        XCTAssertTrue(tabs["Today"].exists)
        XCTAssertTrue(tabs["Lists"].exists)
        XCTAssertTrue(tabs["Progress"].exists)
    }

    func testQuickAddCompleteUndoAndPersistAcrossRelaunch() {
        var app = launch(reset: true)
        app.buttons["addTaskButton"].tap()

        let title = app.textFields["taskTitleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap()
        title.typeText("Finish lab report")
        app.buttons["saveTaskButton"].tap()

        XCTAssertTrue(app.buttons["Complete Finish lab report"].waitForExistence(timeout: 3))

        // Complete via the row's checkbox, then undo.
        app.buttons["Complete Finish lab report"].tap()
        XCTAssertTrue(app.buttons["undoButton"].waitForExistence(timeout: 3))
        app.buttons["undoButton"].tap()
        XCTAssertTrue(app.buttons["Complete Finish lab report"].waitForExistence(timeout: 3))

        // Relaunch without reset: the task must still be there.
        app.terminate()
        app = launch(reset: false)
        XCTAssertTrue(app.buttons["Complete Finish lab report"].waitForExistence(timeout: 5))
    }

    func testEmptyTitleCannotBeSaved() {
        let app = launch(reset: true)
        app.buttons["addTaskButton"].tap()
        let title = app.textFields["taskTitleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap()
        title.typeText("   ")
        XCTAssertFalse(app.buttons["saveTaskButton"].isEnabled)
    }

    func testCreateListFromListsTab() {
        let app = launch(reset: true)
        app.tabBars.buttons["Lists"].tap()
        app.buttons["createListButton"].tap()
        let name = app.textFields["listNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap()
        name.typeText("Thesis")
        app.buttons["saveListButton"].tap()
        // List cards combine their text into one element whose label contains the name.
        let card = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", "Thesis")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3))
    }

    func testSettingsOpensFromProgress() {
        let app = launch(reset: true)
        app.tabBars.buttons["Progress"].tap()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }

    func testStreaksOpenFromProgress() {
        let app = launch(reset: true)
        app.tabBars.buttons["Progress"].tap()
        app.buttons["streaksButton"].tap()
        XCTAssertTrue(app.navigationBars["Streak"].waitForExistence(timeout: 3))
    }

    func testCalendarOpensFromToday() {
        let app = launch(reset: true)
        app.buttons["Calendar"].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(app.tabBars.buttons.count, 3)
    }

    /// Walks every main screen and keeps a screenshot of each in the test result
    /// (CI exports them as an artifact).
    func testScreenshotTour() {
        let app = launch(reset: true)
        snap(app, "10_empty_state")

        for title in ["Finish IR assignment", "Gym - Push Day", "Read 20 pages"] {
            app.buttons["addTaskButton"].firstMatch.tap()
            let field = app.textFields["taskTitleField"]
            XCTAssertTrue(field.waitForExistence(timeout: 3))
            field.tap()
            field.typeText(title)
            if title == "Read 20 pages" { snap(app, "05_add_task") }
            app.buttons["saveTaskButton"].tap()
        }
        let complete = app.buttons["Complete Read 20 pages"]
        XCTAssertTrue(complete.waitForExistence(timeout: 3))
        complete.tap()
        snap(app, "02_today")

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Finish IR assignment")).firstMatch.tap()
        _ = app.buttons["saveTaskButton"].waitForExistence(timeout: 3)
        snap(app, "06_task_detail")
        app.swipeDown(velocity: .fast)

        if app.buttons["Calendar"].waitForExistence(timeout: 3) {
            app.buttons["Calendar"].tap()
            snap(app, "07_calendar")
            app.navigationBars.buttons.firstMatch.tap()
        }

        app.tabBars.buttons["Lists"].tap()
        snap(app, "03_lists")

        app.tabBars.buttons["Progress"].tap()
        snap(app, "04_progress")
        app.buttons["streaksButton"].tap()
        _ = app.navigationBars["Streak"].waitForExistence(timeout: 3)
        snap(app, "08_streaks")
        app.navigationBars.buttons.firstMatch.tap()

        app.buttons["settingsButton"].tap()
        _ = app.navigationBars["Settings"].waitForExistence(timeout: 3)
        snap(app, "09_settings")
    }

    /// Accessibility evidence: Today and Calendar at a large accessibility text size.
    func testLargeTextScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-resetData",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"]
        app.launch()
        app.buttons["addTaskButton"].firstMatch.tap()
        let field = app.textFields["taskTitleField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("Submit thesis chapter draft")
        app.buttons["saveTaskButton"].tap()
        XCTAssertTrue(app.buttons["Complete Submit thesis chapter draft"].waitForExistence(timeout: 3))
        snap(app, "11_today_large_text")
        app.tabBars.buttons["Progress"].tap()
        snap(app, "12_progress_large_text")
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        Thread.sleep(forTimeInterval: 1) // let tab and push transitions settle
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
