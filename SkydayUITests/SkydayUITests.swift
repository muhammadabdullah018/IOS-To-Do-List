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
        title.typeText("Finish lab report")
        app.buttons["saveTaskButton"].tap()

        let row = app.staticTexts["Finish lab report"]
        XCTAssertTrue(row.waitForExistence(timeout: 3))

        // Complete via the checkbox next to the row, then undo.
        app.buttons.matching(NSPredicate(format: "label == %@", "Not completed")).firstMatch.tap()
        XCTAssertTrue(app.buttons["undoButton"].waitForExistence(timeout: 3))
        app.buttons["undoButton"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 3))

        // Relaunch without reset: the task must still be there.
        app.terminate()
        app = launch(reset: false)
        XCTAssertTrue(app.staticTexts["Finish lab report"].waitForExistence(timeout: 5))
    }

    func testEmptyTitleCannotBeSaved() {
        let app = launch(reset: true)
        app.buttons["addTaskButton"].tap()
        let title = app.textFields["taskTitleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.typeText("   ")
        XCTAssertFalse(app.buttons["saveTaskButton"].isEnabled)
    }

    func testCreateListFromListsTab() {
        let app = launch(reset: true)
        app.tabBars.buttons["Lists"].tap()
        app.buttons["createListButton"].tap()
        let name = app.textFields["listNameField"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.typeText("Thesis")
        app.buttons["saveListButton"].tap()
        XCTAssertTrue(app.staticTexts["Thesis"].waitForExistence(timeout: 3))
    }

    func testSettingsOpensFromProgress() {
        let app = launch(reset: true)
        app.tabBars.buttons["Progress"].tap()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }
}
