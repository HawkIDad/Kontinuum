// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncScreen.swift
//  KontinuumUITests
//

import XCTest

/// S9 — Sync Status / Log. Presented as a sheet from the persistent `syncStatusGlyph` toolbar
/// item, present on every main-shell destination.
struct SyncStatusScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Sync Status"] }
    var syncNowButton: XCUIElement { app.button(labeled: "Sync Now") }
    var needsAttentionSection: XCUIElement { app.element(labeled: "Needs Your Attention") }

    /// The queued-conflict row for a given note title — present only once a conflict has been
    /// queued into `ConflictStore.shared` (see `-SeedTestConflict`, `KontinuumApp.swift`).
    func conflictRow(title: String) -> XCUIElement {
        app.button(labeled: "Conflict — \"\(title)\"")
    }

    /// Opens S9 from wherever the main shell currently is — `syncStatusGlyph` is on every
    /// destination's toolbar (see `ContentView.syncStatusToolbarItem`).
    @discardableResult
    func open() -> Self {
        app.buttons["syncStatusGlyph"].tap()
        return self
    }

}
