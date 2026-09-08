// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase3Journey2DailyCaptureFlowTests.swift
//  KontinuumUITests
//
//  Phase 3 — Journey Coverage. Journey 2 (UIUX/02-Journeys.md): daily capture -> journal ->
//  link -> tag -> task, the single highest-frequency flow in the product. Single-device only
//  (the journey's "opens on Mac later" beat is a second-device step, out of this XCUITest's
//  reach the same way Journeys 3/8's live sync race is — Phase 2's
//  `journeyTwoDailyCaptureLinkTagTaskAndCrossDeviceToggle` in `KontinuumTests` already covers
//  that half locally, via a second `DocumentViewModel` over the same store).
//
//  The `[[wikilink autocomplete row itself is exercised separately by Phase 1's journal/S4
//  smoke tests; here the full `[[Title]]` is typed directly (a real, supported way to author a
//  link, not a test shortcut) to keep this journey's own assertions focused on the outcome —
//  link, tag, and task all landing correctly — rather than re-proving the autocomplete UI.
//
//  Verification status: not yet passing in this environment — re-entering the "Projects"
//  Notebook after the journal-write step intermittently can't find/tap its row (the tab-switch-
//  after-day-navigation timing category already documented in
//  `Phase2TaskDashboardAndSavedViewsFeatureTests`, here compounding with a second tab switch in
//  the same test). The individual pieces (linking, tagging, task creation, cross-note Backlinks,
//  Task Dashboard listing) are each already independently verified passing by Phase 1/2's own
//  tests; what isn't yet proven is chaining all of them through this exact journey's navigation
//  sequence in one continuous run. Carried forward honestly rather than force-fitted into a
//  false pass.
//

import XCTest

final class Phase3Journey2DailyCaptureFlowTests: KontinuumUITestCase {

    @MainActor
    func testCaptureLinkTagAndTaskInOneJournalEntry() throws {
        launchAndCreateLibrary()

        // A[Existing note to link to] — created first so the journal's `[[Q3 Roadmap]]` link
        // resolves to a real document, matching the journey's "connected without leaving flow"
        // beat rather than a dangling reference.
        MainShellScreen(app: app).navigate(to: "Notebooks")
        let notebooks = NotebookBrowserScreen(app: app)
        notebooks.createNotebook(named: "Projects")
        let notebookRow = notebooks.notebookRow(name: "Projects")
        XCTAssertTrue(notebookRow.waitForExistence(timeout: 5))
        notebookRow.tap()

        let notebookDocuments = NotebookDocumentsScreen(app: app)
        XCTAssertTrue(app.navigationBars["Projects"].waitForExistence(timeout: 5))
        createFixtureDocument(app: app, notebookDocuments: notebookDocuments, title: "Q3 Roadmap")

        // B[Opens Kontinuum, today's journal already there] -> C[Types a quick line]
        // -> D[[[ links to Q3 Roadmap] -> E[#tag] -> F[- [ ] task]
        MainShellScreen(app: app).navigate(to: "Today")
        let today = TodayJournalScreen(app: app)
        XCTAssertTrue(today.editor.waitForExistence(timeout: 5))
        today.writeAndPersist("\n- Discuss [[Q3 Roadmap]] #standup\n- [ ] Review PR from Dana ")

        // G[Link resolved]: the linked note's Backlinks pane now shows today's journal entry.
        // (See `Phase2TaskDashboardAndSavedViewsFeatureTests`'s note: switching tabs immediately
        // after `writeAndPersist`'s day-navigation round trip is unreliable under XCUITest's
        // synthesized-event timing specifically, confirmed not to reproduce by hand.)
        sleep(3)
        MainShellScreen(app: app).navigate(to: "Notebooks")
        XCTAssertTrue(notebookRow.waitForExistence(timeout: 5))
        notebookRow.tap()
        let roadmapRow = notebookDocuments.documentRow(title: "Q3 Roadmap")
        XCTAssertTrue(roadmapRow.waitForExistence(timeout: 5))
        roadmapRow.tap()

        let roadmapDocument = DocumentScreen(app: app)
        XCTAssertTrue(roadmapDocument.backlinksButton.waitForExistence(timeout: 5))
        roadmapDocument.backlinksButton.tap()
        let backlinks = BacklinksPaneScreen(app: app)
        XCTAssertTrue(backlinks.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(labeledContaining: "Discuss").waitForExistence(timeout: 5))
        app.dismissSheetByDragging()
        XCTAssertTrue(backlinks.navigationTitle.waitForNonExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].tap() // Q3 Roadmap -> Projects

        // H[Task visible on the cross-note Task Dashboard, sourced from the journal entry]
        MainShellScreen(app: app).navigate(to: "Today")
        XCTAssertTrue(today.tasksButton.waitForExistence(timeout: 5))
        today.tasksButton.tap()
        let tasks = TaskDashboardScreen(app: app)
        XCTAssertTrue(tasks.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(tasks.taskRow(containing: "Review PR from Dana").waitForExistence(timeout: 5))
        app.dismissSheetByDragging()

        // I[Previous/Next day navigation still works after all this — the daily habit loop
        // isn't broken by having linked/tagged/tasked content in today's entry]. Next is
        // disabled while already on today, so this round-trips backward first, then forward
        // again, ending back where it started.
        XCTAssertTrue(today.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertFalse(today.nextDayButton.isEnabled)
        today.previousDayButton.tap()
        XCTAssertTrue(today.nextDayButton.waitForExistence(timeout: 5))
        XCTAssertTrue(today.nextDayButton.isEnabled)
        today.nextDayButton.tap()
        XCTAssertTrue(today.editor.waitForExistence(timeout: 5))
        XCTAssertFalse(today.nextDayButton.isEnabled)
    }

}
