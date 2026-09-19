// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase1ConflictResolutionSmokeTests.swift
//  NoteBytezUITests
//
//  Phase 1 — Screen Smoke Coverage. Covers S10 (Conflict Resolution) — reachable only when
//  `ConflictStore.shared` has a queued conflict, which needs a real CloudKit
//  `.serverRecordChanged` error in production. `-SeedTestConflict` (see `NoteBytezApp.swift`)
//  queues a synthetic one at launch so this screen is reachable without live sync, mirroring
//  `NoteBytezTests/JourneyIntegrationTests.swift`'s own in-process fixture. Resolving the
//  conflict for real still needs `-EnableLiveSync` (Phase 4, manual-only) — tapping a resolve
//  action here safely no-ops rather than persisting anything (see `SyncEngine.resolveConflict`'s
//  own early-return when no `CKSyncEngine` is running).
//

import XCTest

final class Phase1ConflictResolutionSmokeTests: NoteBytezUITestCase {

    @MainActor
    func testConflictResolutionRendersKeepAllVersionsLayoutWhenStrategySelected() throws {
        launchAndCreateLibrary(extraArguments: ["-SeedTestConflict"])

        // `ConflictStrategyStore` persists to `UserDefaults.standard`, which — unlike the
        // in-memory SwiftData store — survives across launches on the same simulator. Selecting
        // the strategy explicitly here (rather than relying on whatever the app's own default
        // is) keeps this test deterministic regardless of what a previously-run test in this
        // process last left selected.
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).syncAndConflictsRow.tap()
        ConflictStrategySettingsScreen(app: app).selectStrategy(title: "Keep All Versions")
        app.navigationBars.buttons.element(boundBy: 0).tap() // back to Settings root
        MainShellScreen(app: app).navigate(to: "Today")

        let syncStatus = SyncStatusScreen(app: app).open()
        XCTAssertTrue(syncStatus.needsAttentionSection.waitForExistence(timeout: 5))
        let conflictRow = syncStatus.conflictRow(title: "Flight Notes")
        XCTAssertTrue(conflictRow.waitForExistence(timeout: 5))
        conflictRow.tap()

        let conflict = ConflictResolutionScreen(app: app)
        XCTAssertTrue(conflict.thisDeviceVersionCard.waitForExistence(timeout: 5), "thisDeviceVersionCard: " + String(app.debugDescription.prefix(3000)))
        XCTAssertTrue(conflict.syncedElsewhereVersionCard.exists, "syncedElsewhereVersionCard: " + String(app.debugDescription.prefix(3000)))
        XCTAssertTrue(conflict.keepThisVersionButton.exists, "keepThisVersionButton: " + String(app.debugDescription.prefix(3000)))
        XCTAssertTrue(conflict.keepBothVersionsButton.exists, "keepBothVersionsButton: " + String(app.debugDescription.prefix(3000)))
    }

    /// 20260910v1-Sync.md SF 4 / SF 5 / SF 9 — resolving a conflict clears it from S9 (not just
    /// the glyph count), S10 auto-dismisses back to S9, and once the last one is gone the calm
    /// all-clear state replaces the list. Driven by `-SeedTestConflicts` (a `Document` conflict
    /// "Draft Proposal" + a `Library` conflict "Sync Test"), no live CloudKit.
    @MainActor
    func testResolvingConflictsClearsThemFromSyncStatusAndReturnsToAllClear() throws {
        launch(extraArguments: ["-SeedTestConflicts"])

        // `-SeedTestConflicts` seeds + selects a library and pins the Keep-All-Versions
        // strategy, so the app lands straight on the main shell with S10's manual UI in force —
        // wait for the persistent sync glyph, then open S9 from it.
        XCTAssertTrue(app.buttons["syncStatusGlyph"].waitForExistence(timeout: 15), "did not reach the main shell")

        let sync = SyncStatusScreen(app: app).open()
        XCTAssertTrue(sync.headline("Conflict on 2 notes").waitForExistence(timeout: 5))
        XCTAssertTrue(sync.conflictRow(title: "Draft Proposal").waitForExistence(timeout: 5))

        sync.conflictRow(title: "Draft Proposal").tap()
        let conflict = ConflictResolutionScreen(app: app)
        XCTAssertTrue(conflict.keepThisVersionButton.waitForExistence(timeout: 5))
        conflict.keepThisVersionButton.tap()

        // SF 5 — S10 popped on its own; SF 9 — the row is gone, not merely the count.
        XCTAssertTrue(sync.navigationTitle.waitForExistence(timeout: 5))
        // SF 7 — the transient Undo affordance is presented after a manual resolution.
        XCTAssertTrue(sync.undoButton.waitForExistence(timeout: 3))
        XCTAssertTrue(sync.conflictRow(title: "Draft Proposal").waitForNonExistence(timeout: 5))
        XCTAssertTrue(sync.conflictRow(title: "Sync Test").exists)
        XCTAssertTrue(sync.headline("Conflict on 1 note").waitForExistence(timeout: 5))

        sync.conflictRow(title: "Sync Test").tap()
        XCTAssertTrue(conflict.keepThisVersionButton.waitForExistence(timeout: 5))
        conflict.keepThisVersionButton.tap()

        // SF 4 — last conflict gone → calm all-clear state, glyph back to Synced.
        XCTAssertTrue(sync.noConflictsRow.waitForExistence(timeout: 5))
        XCTAssertTrue(sync.headline("Synced").waitForExistence(timeout: 5))
    }

    @MainActor
    func testConflictResolutionRendersDiffMergeLayoutWhenStrategySelected() throws {
        launchAndCreateLibrary(extraArguments: ["-SeedTestConflict"])

        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).syncAndConflictsRow.tap()
        ConflictStrategySettingsScreen(app: app).selectStrategy(title: "Markdown Diff-Merge")
        app.navigationBars.buttons.element(boundBy: 0).tap() // back to Settings root
        MainShellScreen(app: app).navigate(to: "Today")

        let syncStatus = SyncStatusScreen(app: app).open()
        let conflictRow = syncStatus.conflictRow(title: "Flight Notes")
        XCTAssertTrue(conflictRow.waitForExistence(timeout: 5))
        conflictRow.tap()

        let conflict = ConflictResolutionScreen(app: app)
        XCTAssertTrue(conflict.saveMergedNoteButton.waitForExistence(timeout: 5))
    }

}
