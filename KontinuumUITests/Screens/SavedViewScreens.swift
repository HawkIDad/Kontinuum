// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedViewScreens.swift
//  KontinuumUITests
//

import XCTest

/// S21 — Saved Views. Sidebar-only entry point (Mac/iPad regular width) — no iPhone tab bar
/// slot; on iPhone, saved views are folded into the top of S7/S19 instead (see
/// `SearchScreen`/`TaskDashboardScreen`'s `SavedViewChip` rows).
struct SavedViewsListScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Saved Views"] }

    func savedViewRow(name: String) -> XCUIElement {
        app.element(labeledContaining: name)
    }

}
