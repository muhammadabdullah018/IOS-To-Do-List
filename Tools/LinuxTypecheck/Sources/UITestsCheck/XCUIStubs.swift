// XCUITest TYPE-CHECK STUB (Linux XCTest has no UI testing). Same-module declarations so
// SkydayUITests.swift type-checks; signatures mirror Apple's XCUIAutomation API subset.
import Foundation
import XCTest

enum XCUIElementType { case any, button, staticText, textField }

final class XCUIElement {
    var exists: Bool { false }
    var isEnabled: Bool { false }
    func waitForExistence(timeout: TimeInterval) -> Bool { false }
    func tap() {}
    func typeText(_ text: String) {}
}

final class XCUIElementQuery {
    subscript(_ identifier: String) -> XCUIElement { XCUIElement() }
    var firstMatch: XCUIElement { XCUIElement() }
    var count: Int { 0 }
    func matching(_ predicate: NSPredicate) -> XCUIElementQuery { self }
    func matching(identifier: String) -> XCUIElementQuery { self }
}

class XCUIApplication {
    init() {}
    var launchArguments: [String] = []
    func launch() {}
    func terminate() {}
    var buttons: XCUIElementQuery { XCUIElementQuery() }
    var textFields: XCUIElementQuery { XCUIElementQuery() }
    var staticTexts: XCUIElementQuery { XCUIElementQuery() }
    var navigationBars: XCUIElementQuery { XCUIElementQuery() }
    func descendants(matching type: XCUIElementType) -> XCUIElementQuery { XCUIElementQuery() }
}

/// Module-local stand-in: swift-corelibs-foundation doesn't support format predicates.
/// Shadows Foundation.NSPredicate inside this check target only.
final class NSPredicate {
    init(format: String, _ args: CVarArg...) {}
}
