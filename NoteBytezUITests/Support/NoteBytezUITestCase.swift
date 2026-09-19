// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NoteBytezUITestCase.swift
//  NoteBytezUITests
//

import XCTest

/// Shared launch/setup for every phase's UI tests. Debug builds run against an in-memory store
/// (see `NoteBytezApp.swift`), so every launch starts with zero libraries and lands on S1 —
/// there is no persisted state to clean up between tests.
class NoteBytezUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    /// Launches the app. Every launch path in this suite should go through this (or
    /// `launchAndCreateLibrary` below), not `app.launch()` directly — it's the one shared choke
    /// point that passes `-SkipLanguagePrompt` by default (MultiLanguage Phase 5.7, R7): the
    /// first-launch language prompt now precedes S1 in `RootView`, and every existing test
    /// expects to land directly on S1 or the main shell.
    func launch(extraArguments: [String] = []) {
        app.launchArguments += ["-SkipLanguagePrompt"] + extraArguments
        app.launch()
    }

    /// Launches the app (with any extra launch arguments, e.g. `-SeedTestConflict`) and creates
    /// a fresh library from S1, landing on the main shell's Today tab.
    @discardableResult
    func launchAndCreateLibrary(named name: String = "UI Test Library", extraArguments: [String] = []) -> XCUIApplication {
        launch(extraArguments: extraArguments)
        LibrarySelectionScreen(app: app).createLibrary(named: name)
        return app
    }

}
