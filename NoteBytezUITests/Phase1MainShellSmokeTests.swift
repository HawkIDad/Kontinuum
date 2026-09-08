// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase1MainShellSmokeTests.swift
//  NoteBytezUITests
//
//  Phase 1 — Screen Smoke Coverage (see Docs/Plans/NoteBytez20260823v1-UITests.md). Covers every
//  screen reachable directly from the main navigation shell: S3 (Today), S9 (Sync Status), S14
//  (Notebooks, empty state), S7 (Search), S8 (Graph, via TodayGraphView), and the Settings root.
//

import XCTest

final class Phase1MainShellSmokeTests: NoteBytezUITestCase {

    @MainActor
    func testTodayJournalRenders() throws {
        launchAndCreateLibrary()
        let today = TodayJournalScreen(app: app)
        XCTAssertTrue(today.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(today.editor.exists)
        XCTAssertTrue(today.quickSwitcherButton.exists)
        XCTAssertTrue(today.promoteButton.exists)
        XCTAssertTrue(today.tasksButton.exists)
    }

    @MainActor
    func testSyncStatusSheetRendersFromEveryDestination() throws {
        launchAndCreateLibrary()
        let syncStatus = SyncStatusScreen(app: app).open()
        XCTAssertTrue(syncStatus.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(syncStatus.syncNowButton.exists)
        app.dismissSheetByDragging()
    }

    @MainActor
    func testNotebookBrowserRendersEmptyState() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Notebooks")
        let notebooks = NotebookBrowserScreen(app: app)
        XCTAssertTrue(notebooks.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(notebooks.newNotebookButton.exists)
        XCTAssertTrue(notebooks.canvasButton.exists)
    }

    @MainActor
    func testSearchScreenRenders() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Search")
        let search = SearchScreen(app: app)
        XCTAssertTrue(search.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(search.searchField.exists)
        search.searchField.tap()
        search.searchField.typeText("roadmap")
        XCTAssertTrue(search.advancedModeToggleOff.exists)
    }

    @MainActor
    func testGraphScreenRendersForTodayEntry() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Graph")
        let graph = GraphScreen(app: app)
        XCTAssertTrue(graph.zoomInButton.waitForExistence(timeout: 5))
        XCTAssertTrue(graph.zoomOutButton.exists)
        XCTAssertTrue(graph.fitToScreenButton.exists)
    }

    @MainActor
    func testSettingsRootRenders() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Settings")
        let settings = SettingsScreen(app: app)
        XCTAssertTrue(settings.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(settings.syncAndConflictsRow.exists)
        XCTAssertTrue(settings.backupsRow.exists)
        XCTAssertTrue(settings.templatesRow.exists)
        XCTAssertTrue(settings.pluginsRow.exists)
        XCTAssertTrue(settings.sharingRow.exists)
        XCTAssertTrue(settings.exportLibraryRow.exists)
    }

}
