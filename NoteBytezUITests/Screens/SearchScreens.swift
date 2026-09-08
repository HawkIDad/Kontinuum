// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SearchScreens.swift
//  NoteBytezUITests
//

import XCTest

/// S6 — Quick Switcher.
struct QuickSwitcherScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Quick Switcher"] }
    var searchField: XCUIElement { app.textFields["Search notes..."] }
    var cancelButton: XCUIElement { app.button(labeled: "Cancel") }

}

/// S7 — Search Results.
struct SearchScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Search"] }
    var searchField: XCUIElement { app.textFields["Search"] }
    /// The label reflects live on/off state, so this only matches while off.
    var advancedModeToggleOff: XCUIElement { app.button(labeled: "Advanced Search: Off") }
    var advancedModeToggleOn: XCUIElement { app.button(labeled: "Advanced Search: On") }
    var advancedFieldPlaceholder: XCUIElement { app.textFields["#tag AND \"phrase\" NOT /regex/"] }
    var saveSearchButton: XCUIElement { app.button(labeled: "Save This Search") }

    // "Save Search" alert
    var saveSearchNameField: XCUIElement { app.textFields["Name"] }
    var saveSearchConfirmButton: XCUIElement { app.alerts.buttons["Save"] }

    func savedViewChip(name: String) -> XCUIElement { app.element(labeledContaining: name) }

}
