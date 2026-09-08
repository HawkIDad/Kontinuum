// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SettingsScreens.swift
//  KontinuumUITests
//

import XCTest

/// Settings root — reached via the "Settings" sidebar/tab bar destination.
struct SettingsScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Settings"] }
    var syncAndConflictsRow: XCUIElement { app.button(labeled: "Sync & Conflicts") }
    var backupsRow: XCUIElement { app.button(labeled: "Backups") }
    var templatesRow: XCUIElement { app.button(labeled: "Templates") }
    var pluginsRow: XCUIElement { app.button(labeled: "Plugins") }
    var sharingRow: XCUIElement { app.button(labeled: "Sharing") }
    var exportLibraryRow: XCUIElement { app.button(labeled: "Export Library") }

}

/// S11 — Settings: Conflict Strategy.
struct ConflictStrategySettingsScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Sync & Conflicts"] }

    func strategyRow(title: String) -> XCUIElement {
        app.element(labeledContaining: title)
    }

    func selectStrategy(title: String) {
        strategyRow(title: title).tap()
    }

}
