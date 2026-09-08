// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagScreen.swift
//  KontinuumUITests
//

import XCTest

/// S13 — Tag Browser. Sidebar-only entry point (Mac/iPad regular width) — no iPhone tab bar
/// slot per `ContentView.AppDestination.tabBarDestinations`; reachable on iPhone only via an
/// in-context tag chip tap, which needs a persisted, tagged document first.
struct TagBrowserScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Tags"] }

    func tagRow(name: String) -> XCUIElement {
        app.element(labeledContaining: "#\(name)")
    }

}
