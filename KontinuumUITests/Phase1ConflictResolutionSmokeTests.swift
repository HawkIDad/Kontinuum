// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase1ConflictResolutionSmokeTests.swift
//  KontinuumUITests
//
//  Phase 1 — Screen Smoke Coverage. Covers S10 (Conflict Resolution) — reachable only when
//  `ConflictStore.shared` has a queued conflict, which needs a real CloudKit
//  `.serverRecordChanged` error in production. `-SeedTestConflict` (see `KontinuumApp.swift`)
//  queues a synthetic one at launch so this screen is reachable without live sync, mirroring
//  `KontinuumTests/JourneyIntegrationTests.swift`'s own in-process fixture. Resolving the
//  conflict for real still needs `-EnableLiveSync` (Phase 4, manual-only) — tapping a resolve
//  action here safely no-ops rather than persisting anything (see `SyncEngine.resolveConflict`'s
//  own early-return when no `CKSyncEngine` is running).
//

import XCTest

final class Phase1ConflictResolutionSmokeTests: KontinuumUITestCase {

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
