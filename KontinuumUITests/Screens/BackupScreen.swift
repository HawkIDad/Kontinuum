// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BackupScreen.swift
//  KontinuumUITests
//

import XCTest

/// S12 — Backup & Restore.
struct BackupRestoreScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Backups"] }
    var createBackupButton: XCUIElement { app.button(labeled: "Create Backup") }

}
