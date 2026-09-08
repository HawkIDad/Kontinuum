// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase1JournalFlowSmokeTests.swift
//  NoteBytezUITests
//
//  Phase 1 — Screen Smoke Coverage. Covers S13 (Tag Browser, reached on iPhone via a journal
//  tag chip tap — the one compact-width path into it, since it has no tab bar/sidebar slot on
//  iPhone), S15 (Promote to Notebook, and its block-picker entry point), S6 (Quick Switcher),
//  and S19 (Task Dashboard) — all reached from S3 (Today)'s toolbar, the way a real iPhone user
//  reaches them.
//

import XCTest

final class Phase1JournalFlowSmokeTests: NoteBytezUITestCase {

    @MainActor
    func testJournalTagChipOpensTagBrowserAndTaggedDocuments() throws {
        launchAndCreateLibrary()
        let today = TodayJournalScreen(app: app)
        today.writeAndPersist("\n- Discuss project #standup\n- [ ] Review PR from Dana")

        let tagChip = app.button(labeled: "#standup")
        XCTAssertTrue(tagChip.waitForExistence(timeout: 5), "tagChip: " + String(app.debugDescription.prefix(3000)))
        tagChip.tap()

        // S13 — Tag Browser
        let tagBrowser = TagBrowserScreen(app: app)
        XCTAssertTrue(tagBrowser.navigationTitle.waitForExistence(timeout: 5), "tagBrowser.navigationTitle: " + String(app.debugDescription.prefix(3000)))
        let standupRow = tagBrowser.tagRow(name: "standup")
        XCTAssertTrue(standupRow.waitForExistence(timeout: 5), "standupRow: " + String(app.debugDescription.prefix(3000)))
        standupRow.tap()

        // Tagged-documents drill-down (S13's own "tap a tag to jump into filtered notes")
        XCTAssertTrue(app.element(labeledContaining: "standup").waitForExistence(timeout: 5), "drilldown: " + String(app.debugDescription.prefix(3000)))
    }

    @MainActor
    func testPromoteToNotebookFlowRenders() throws {
        launchAndCreateLibrary()
        let today = TodayJournalScreen(app: app)
        today.writeAndPersist("\n- Idea: revamp the onboarding flow")

        XCTAssertTrue(today.promoteButton.waitForExistence(timeout: 5))
        today.promoteButton.tap()

        let blockPicker = PromoteBlockPickerScreen(app: app)
        XCTAssertTrue(blockPicker.navigationTitle.waitForExistence(timeout: 5))
        let blockRow = blockPicker.blockRow(containing: "Idea: revamp the onboarding flow")
        XCTAssertTrue(blockRow.waitForExistence(timeout: 5), String(app.debugDescription.prefix(4000)))
        blockRow.tap()

        // S15 — Promote to Notebook
        let promote = PromoteToNotebookScreen(app: app)
        XCTAssertTrue(promote.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(promote.newNotebookNameField.exists)
        promote.newNotebookNameField.tap()
        promote.newNotebookNameField.typeText("Onboarding Revamp")
        XCTAssertTrue(promote.promoteButton.isEnabled)
        promote.promoteButton.tap()

        // Lands back on Today, having pushed the newly-promoted Document (S4).
        let document = DocumentScreen(app: app)
        XCTAssertTrue(document.titleField.waitForExistence(timeout: 5))
    }

    @MainActor
    func testQuickSwitcherAndTaskDashboardRenderFromTodayToolbar() throws {
        launchAndCreateLibrary()
        let today = TodayJournalScreen(app: app)

        today.quickSwitcherButton.tap()
        let quickSwitcher = QuickSwitcherScreen(app: app)
        XCTAssertTrue(quickSwitcher.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(quickSwitcher.searchField.exists)
        quickSwitcher.cancelButton.tap()

        XCTAssertTrue(today.tasksButton.waitForExistence(timeout: 5))
        today.tasksButton.tap()
        let tasks = TaskDashboardScreen(app: app)
        XCTAssertTrue(tasks.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(tasks.tagFilterField.exists)
        app.dismissSheetByDragging()
    }

}
