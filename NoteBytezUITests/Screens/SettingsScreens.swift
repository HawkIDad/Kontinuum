// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SettingsScreens.swift
//  NoteBytezUITests
//

import XCTest

/// Settings root — reached via the "Settings" sidebar/tab bar destination.
struct SettingsScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Settings"] }
    var languageRow: XCUIElement { app.button(labeled: "Language") }
    var syncAndConflictsRow: XCUIElement { app.button(labeled: "Sync & Conflicts") }
    var backupsRow: XCUIElement { app.button(labeled: "Backups") }
    var templatesRow: XCUIElement { app.button(labeled: "Templates") }
    var pluginsRow: XCUIElement { app.button(labeled: "Plugins") }
    var sharingRow: XCUIElement { app.button(labeled: "Sharing") }
    var exportLibraryRow: XCUIElement { app.button(labeled: "Export Library") }

}

/// First-launch language prompt (MultiLanguage Phase 5.4) — precedes S1 and the entitlement gate.
struct LanguagePromptScreen {

    let app: XCUIApplication

    var continueButton: XCUIElement { app.buttons["primaryButton.Continue"] }

    func option(forLocaleId id: String) -> XCUIElement {
        app.buttons["languagePrompt.option.\(id)"]
    }

    func confirm() {
        continueButton.tap()
    }

}

/// Settings → Language (MultiLanguage Phase 5.5).
struct LanguageSettingsScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Language"] }
    var systemDefaultRow: XCUIElement { app.buttons["languageSettings.option.system"] }

    func row(forLocaleId id: String) -> XCUIElement {
        app.buttons["languageSettings.option.\(id)"]
    }

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
