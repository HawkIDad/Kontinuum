//
//  NoteBytezUITests.swift
//  NoteBytezUITests
//
//  Created by David Collison on 8/13/26.
//

import XCTest

/// Phase 0 foundation smoke test — proves the accessibility identifiers added to
/// `LibrarySelectionView`'s `PrimaryButton`s and `ContentView`'s sidebar/tab bar rows are
/// queryable, and that a `MainShellScreen` page object can drive navigation across platforms.
/// Full per-screen and per-journey coverage is built out in later phases (see
/// Docs/Plans/NoteBytez20260823v1-UITests.md).
final class NoteBytezUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testCreateLibraryThenNavigateMainShellByAccessibilityIdentifier() throws {
        // Debug builds run against an in-memory store (see NoteBytezApp.swift), so every launch
        // starts with zero libraries and lands on S1 — Library Selection.
        let createLibraryButton = app.buttons["primaryButton.Create New Library"]
        XCTAssertTrue(createLibraryButton.waitForExistence(timeout: 5))
        createLibraryButton.tap()

        let nameField = app.textFields["Library Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("UI Test Library")

        app.buttons["primaryButton.Create"].tap()

        let mainShell = MainShellScreen(app: app)
        mainShell.navigate(to: "Search")

        let searchTitle = app.descendants(matching: .any).matching(
            NSPredicate(format: "label == %@", "Search")
        ).firstMatch
        XCTAssertTrue(searchTitle.waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
