// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase2PluginManagementFeatureTests.swift
//  KontinuumUITests
//
//  Phase 2 — Feature Coverage: Plugin SDK (preview, V1). Installs a real plugin with one
//  explicitly granted permission and confirms it appears enabled with that permission named on
//  the list row, then disables it — not just that the install sheet renders (already covered by
//  Phase 1). Exercises Decisions Log #3's "every permission is user-visible before a plugin can
//  run" guarantee end-to-end rather than just reading the code.
//
//  Verification status: not yet passing in this environment — the plugin installs (Phase 1
//  already confirms the sheet flow itself works), but the granted-permission toggle isn't
//  reliably registering before "Install" is tapped, so the result lists "No permissions
//  granted" instead of "Read library". Same keyboard-focus-timing category as this suite's other
//  documented gaps (`Phase2TaskDashboardAndSavedViewsFeatureTests`,
//  `Phase2BlockReferencesFeatureTests`, `Phase2CanvasFeatureTests`) — carried forward honestly
//  rather than force-fitted into a false pass.
//

import XCTest

final class Phase2PluginManagementFeatureTests: KontinuumUITestCase {

    @MainActor
    func testInstalledPluginShowsGrantedPermissionAndCanBeDisabled() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).pluginsRow.tap()

        let plugins = PluginManagementScreen(app: app)
        XCTAssertTrue(plugins.navigationTitle.waitForExistence(timeout: 5))
        plugins.addButton.tap()

        let install = PluginInstallScreen(app: app)
        XCTAssertTrue(install.navigationTitle.waitForExistence(timeout: 5))
        install.nameField.tap()
        // The keyboard is still up and covers the bottom of the Form, where the permission
        // toggles live — a tap there lands on the keyboard, not the toggle underneath it. A
        // trailing return resigns this single-line field's focus (unlike a multiline
        // `TextEditor`, where return only inserts a newline).
        install.nameField.typeText("Word Count\n")

        let permissionToggle = install.permissionToggle("Read library")
        XCTAssertTrue(permissionToggle.waitForExistence(timeout: 5))
        permissionToggle.tap()

        // The entry-script `TextEditor` needs non-empty content for "Install" to enable.
        let scriptEditor = app.textViews.firstMatch
        XCTAssertTrue(scriptEditor.waitForExistence(timeout: 5))
        scriptEditor.tap()
        scriptEditor.typeText("// count words")

        XCTAssertTrue(install.installButton.isEnabled)
        install.installButton.tap()

        XCTAssertTrue(plugins.navigationTitle.waitForExistence(timeout: 5))
        let toggle = plugins.pluginToggle(name: "Word Count")
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        XCTAssertEqual(toggle.value as? String, "1")
        XCTAssertTrue(plugins.permissionsSummary(containing: "Read library").waitForExistence(timeout: 5))

        toggle.tap()
        XCTAssertEqual(toggle.value as? String, "0")
    }

}
