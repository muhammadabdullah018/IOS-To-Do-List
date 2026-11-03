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
        // Custom floating tab bar: exactly three tab buttons.
        for id in ["tabToday", "tabLists", "tabProgress"] {
            XCTAssertTrue(app.buttons[id].exists, "missing \(id)")
        }
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'tab'")).count, 3)
    }

    func testQuickAddCompleteUndoAndPersistAcrossRelaunch() {
        var app = launch(reset: true)
        app.buttons["addTaskButton"].tap()

        let title = app.textFields["taskTitleField"]
        XCTAssertTrue(title.waitForExistence(timeout: 3))
        title.tap()
        title.typeText("Finish lab report")
        app.buttons["saveTaskButton"].tap()

        // Task cards are buttons whose label starts with the title.
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Finish lab report")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 3))

        // Complete via the card's check button, then undo.
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
        app.buttons["tabLists"].tap()
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
        app.buttons["tabProgress"].tap()
        app.buttons["settingsButton"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
    }
}
