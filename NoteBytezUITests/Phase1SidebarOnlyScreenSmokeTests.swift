// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase1SidebarOnlyScreenSmokeTests.swift
//  NoteBytezUITests
//
//  Phase 1 — Screen Smoke Coverage. Covers "All Notes" and S21 (Saved Views) — both sidebar-only
//  destinations on Mac/iPad regular width (see `ContentView.AppDestination.tabBarDestinations`,
//  which omits both). They have no compact-width (iPhone) entry point at all, so these tests
//  skip themselves — rather than failing — when run on a compact-width destination; re-running
//  the Phase 1 suite on iPad/Mac (this phase's own second step) is what actually exercises them.
//

import XCTest

final class Phase1SidebarOnlyScreenSmokeTests: NoteBytezUITestCase {

    @MainActor
    func testAllNotesRendersOnRegularWidth() throws {
        launchAndCreateLibrary()
        let sidebarRow = app.sidebarRow("All Notes")
        try XCTSkipUnless(sidebarRow.waitForExistence(timeout: 3), "Compact width (iPhone) has no sidebar — see Phase 1's iPad/Mac re-run step.")
        sidebarRow.tap()

        let allNotes = DocumentListScreen(app: app)
        XCTAssertTrue(allNotes.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(allNotes.newNoteButton.exists)
    }

    @MainActor
    func testSavedViewsRendersOnRegularWidth() throws {
        launchAndCreateLibrary()
        let sidebarRow = app.sidebarRow("Saved Views")
        try XCTSkipUnless(sidebarRow.waitForExistence(timeout: 3), "Compact width (iPhone) has no sidebar — see Phase 1's iPad/Mac re-run step.")
        sidebarRow.tap()

        let savedViews = SavedViewsListScreen(app: app)
        XCTAssertTrue(savedViews.navigationTitle.waitForExistence(timeout: 5))
    }

}
