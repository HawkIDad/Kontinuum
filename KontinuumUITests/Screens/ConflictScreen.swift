// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictScreen.swift
//  KontinuumUITests
//

import XCTest

/// S10 — Conflict Resolution. Which sub-UI renders depends on the active
/// `ConflictStrategyStore` selection (see `ConflictStrategySettingsScreen`) and whether the
/// conflict has diffable content — `-SeedTestConflict`'s fixture always does.
struct ConflictResolutionScreen {

    let app: XCUIApplication

    // Keep All Versions sub-UI. `ConflictVersionCard` combines its label/timestamp/snippet into
    // one accessibility element per card, so these are substring matches, not exact.
    var thisDeviceVersionCard: XCUIElement { app.element(labeledContaining: "This Device") }
    var syncedElsewhereVersionCard: XCUIElement { app.element(labeledContaining: "Synced Elsewhere") }
    /// One "Keep This Version" button per `ConflictVersionCard` — `firstMatch` is enough to
    /// confirm the strategy's per-version keep action is present.
    var keepThisVersionButton: XCUIElement { app.button(labeled: "Keep This Version") }
    var keepBothVersionsButton: XCUIElement { app.button(labeled: "Keep Both Versions") }

    // Markdown Diff-Merge sub-UI.
    var saveMergedNoteButton: XCUIElement { app.button(labeled: "Save Merged Note") }

}
