// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase1SettingsSmokeTests.swift
//  KontinuumUITests
//
//  Phase 1 — Screen Smoke Coverage. Covers every screen reached from Settings: S11 (Sync &
//  Conflicts strategy), S12 (Backup & Restore), S18's Manager sub-flow (Template Groups), S24
//  (Plugin Management, plus its install-approval sheet), and S22 (Sharing / Participants).
//

import XCTest

final class Phase1SettingsSmokeTests: KontinuumUITestCase {

    @MainActor
    func testConflictStrategySettingsRendersAllThreeOptions() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).syncAndConflictsRow.tap()

        let strategySettings = ConflictStrategySettingsScreen(app: app)
        XCTAssertTrue(strategySettings.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(strategySettings.strategyRow(title: "Keep All Versions").exists)
        XCTAssertTrue(strategySettings.strategyRow(title: "Last-Write-Wins + Banner").exists)
        XCTAssertTrue(strategySettings.strategyRow(title: "Markdown Diff-Merge").exists)
        strategySettings.selectStrategy(title: "Keep All Versions")
    }

    @MainActor
    func testBackupRestoreScreenRendersAndCreatesManualSnapshot() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).backupsRow.tap()

        let backups = BackupRestoreScreen(app: app)
        XCTAssertTrue(backups.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(backups.createBackupButton.exists)
        backups.createBackupButton.tap()
        // Screen still renders after the action — a manual snapshot doesn't crash or navigate away.
        XCTAssertTrue(backups.navigationTitle.exists)
    }

    @MainActor
    func testTemplateGroupManagerRendersAndCreatesGroup() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).templatesRow.tap()

        let templates = TemplateGroupListScreen(app: app)
        XCTAssertTrue(templates.navigationTitle.waitForExistence(timeout: 5))
        templates.createGroup(named: "Fiction Writing")
        XCTAssertTrue(app.element(labeledContaining: "Fiction Writing").waitForExistence(timeout: 5))
    }

    @MainActor
    func testPluginManagementRendersAndInstallSheetOpens() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).pluginsRow.tap()

        let plugins = PluginManagementScreen(app: app)
        XCTAssertTrue(plugins.navigationTitle.waitForExistence(timeout: 5))
        plugins.addButton.tap()

        let install = PluginInstallScreen(app: app)
        XCTAssertTrue(install.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(install.nameField.exists)
        install.nameField.tap()
        install.nameField.typeText("Word Count")
        install.cancelButton.tap()
    }

    @MainActor
    func testSharingScreenRendersNotSharedEmptyState() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).sharingRow.tap()

        let sharing = SharingParticipantsScreen(app: app)
        XCTAssertTrue(sharing.doneButton.waitForExistence(timeout: 5))
        XCTAssertTrue(sharing.notSharedEmptyState.waitForExistence(timeout: 5))
        sharing.doneButton.tap()
    }

}
