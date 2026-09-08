// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginScreen.swift
//  NoteBytezUITests
//

import XCTest

/// S24 — Plugin Management. Reached from Settings → "Plugins".
struct PluginManagementScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Plugins (Preview)"] }
    var addButton: XCUIElement { app.button(labeled: "Add") }

    func pluginToggle(name: String) -> XCUIElement { app.switches[name] }
    func permissionsSummary(containing text: String) -> XCUIElement { app.element(labeledContaining: text) }

}

/// The install-approval sheet — per Decisions Log #3, every permission is shown and granted
/// individually, never a bare "trust this plugin" toggle.
struct PluginInstallScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Add Plugin"] }
    var nameField: XCUIElement { app.textFields["Name"] }
    var installButton: XCUIElement { app.button(labeled: "Install") }
    var cancelButton: XCUIElement { app.button(labeled: "Cancel") }

    func permissionToggle(_ displayName: String) -> XCUIElement {
        app.switches[displayName]
    }

}
