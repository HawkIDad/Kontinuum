// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  KontinuumUITestCase.swift
//  KontinuumUITests
//

import XCTest

/// Shared launch/setup for every phase's UI tests. Debug builds run against an in-memory store
/// (see `KontinuumApp.swift`), so every launch starts with zero libraries and lands on S1 —
/// there is no persisted state to clean up between tests.
class KontinuumUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// Launches the app (with any extra launch arguments, e.g. `-SeedTestConflict`) and creates
    /// a fresh library from S1, landing on the main shell's Today tab.
    @discardableResult
    func launchAndCreateLibrary(named name: String = "UI Test Library", extraArguments: [String] = []) -> XCUIApplication {
        app.launchArguments += extraArguments
        app.launch()
        LibrarySelectionScreen(app: app).createLibrary(named: name)
        return app
    }

}
