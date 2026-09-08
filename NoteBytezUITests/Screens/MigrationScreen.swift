// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationScreen.swift
//  NoteBytezUITests
//

import XCTest

/// S23 — Migration Assistant. Reached only after the system folder picker (triggered by
/// `LibrarySelectionScreen.migrationAssistantButton`) resolves a folder — the same
/// simulator/system-UI picker automation gap noted for S2.
struct MigrationAssistantScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Migration Assistant"] }
    var cancelButton: XCUIElement { app.button(labeled: "Cancel") }
    var confirmMigrationButton: XCUIElement { app.button(labeled: "Confirm Migration") }

}
