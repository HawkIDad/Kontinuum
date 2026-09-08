// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase2BackupRestoreFeatureTests.swift
//  NoteBytezUITests
//
//  Phase 2 — Feature Coverage: Backups (MVP). Creates a manual snapshot, then actually performs
//  a Restore through the confirmation dialog — not just that tapping "Create Backup" leaves the
//  screen intact (already covered by Phase 1).
//

import XCTest

final class Phase2BackupRestoreFeatureTests: NoteBytezUITestCase {

    @MainActor
    func testManualBackupCanBeRestored() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).backupsRow.tap()

        let backups = BackupRestoreScreen(app: app)
        XCTAssertTrue(backups.navigationTitle.waitForExistence(timeout: 5))
        backups.createBackupButton.tap()

        let restoreButton = app.button(labeled: "Restore")
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5))
        restoreButton.tap()

        // `.confirmationDialog("Restore this backup?", ...)` — an action sheet, not an alert.
        let confirmRestore = app.sheets.buttons["Restore"].exists ? app.sheets.buttons["Restore"] : app.buttons["Restore"]
        XCTAssertTrue(confirmRestore.waitForExistence(timeout: 5))
        confirmRestore.tap()

        // Screen survives the restore and still shows the snapshot — the real assertion here is
        // that `viewModel.restore(_:)` didn't crash the app or leave it in a broken state.
        XCTAssertTrue(backups.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(restoreButton.waitForExistence(timeout: 5))
    }

}
