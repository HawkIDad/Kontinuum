// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncScreen.swift
//  NoteBytezUITests
//

import XCTest

/// S9 — Sync Status / Log. Presented as a sheet from the persistent `syncStatusGlyph` toolbar
/// item, present on every main-shell destination.
struct SyncStatusScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Sync Status"] }
    var syncNowButton: XCUIElement { app.button(labeled: "Sync Now") }
    var needsAttentionSection: XCUIElement { app.element(labeled: "Needs Your Attention") }

    /// SF 4 — the calm all-clear row shown once every conflict is resolved.
    var noConflictsRow: XCUIElement { app.element(labeled: "No conflicts — you're all synced") }
    /// SF 4 — the transient "Resolved ✓" row for a just-resolved conflict.
    var resolvedAckRow: XCUIElement { app.element(labeledContaining: "Resolved — kept") }
    /// SF 7 — the "Undo" button in the transient resolution toast.
    var undoButton: XCUIElement { app.button(labeled: "Undo") }

    /// The status headline next to the glyph — "Synced" / "Conflict on N notes".
    func headline(_ text: String) -> XCUIElement { app.element(labeled: text) }

    /// The queued-conflict row for a given note title — present only once a conflict has been
    /// queued into `ConflictStore.shared` (see `-SeedTestConflict`, `NoteBytezApp.swift`).
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
