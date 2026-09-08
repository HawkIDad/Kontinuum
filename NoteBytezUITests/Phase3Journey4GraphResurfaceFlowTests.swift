// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase3Journey4GraphResurfaceFlowTests.swift
//  KontinuumUITests
//
//  Phase 3 — Journey Coverage. Journey 4 (UIUX/02-Journeys.md): a keyword search misses, the
//  local graph misses too (MVP's graph is intentionally shallow — current note + direct links
//  only), so the user falls back to a tag and finds the half-remembered note via the Tag
//  Browser, then closes the loop by linking to it.
//
//  Verification status: not yet passing in this environment — re-entering "Notebooks" after
//  typing into the Search field intermittently can't find/tap the fixture Notebook's row
//  afterward. Traced further than the same symptom elsewhere in this session: XCUITest's own
//  tap synthesis for the tab bar item computes a degenerate `{-1, -1}` hit point in this
//  specific screen transition — confirmed via `xcresulttool`'s activity log, and confirmed
//  independent of typing/keyboard state (a `sleep(3)` before it made no difference). A
//  coordinate-based tap on the tab bar item's own frame was tried as a workaround and didn't
//  reliably fix it either (and risked destabilizing `MainShellScreen.navigate`, used by every
//  other passing test in this suite, so it was reverted rather than kept half-working). Each
//  individual step (search miss, graph miss, tag chip -> Tag Browser -> tagged documents,
//  wikilink creation, cross-note Backlinks) is independently proven by Phase 1/2/4's own
//  `KontinuumTests` (`journeyFourSearchMissesGraphMissesTagBrowserFindsThenLinksBack`, in-process,
//  not UI-driven) and this suite's other tests; what isn't yet proven is this exact
//  Search-then-Notebooks tab sequence specifically. Carried forward honestly rather than
//  force-fitted into a false pass.
//

import XCTest

final class Phase3Journey4GraphResurfaceFlowTests: KontinuumUITestCase {

    @MainActor
    func testSearchAndGraphMissThenTagBrowserFindsAndLinksBack() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Notebooks")

        let notebooks = NotebookBrowserScreen(app: app)
        notebooks.createNotebook(named: "Journey4 Fixture")
        let notebookRow = notebooks.notebookRow(name: "Journey4 Fixture")
        XCTAssertTrue(notebookRow.waitForExistence(timeout: 5))
        notebookRow.tap()

        let notebookDocuments = NotebookDocumentsScreen(app: app)
        XCTAssertTrue(app.navigationBars["Journey4 Fixture"].waitForExistence(timeout: 5))

        // The current note (no direct link to the forgotten one) and the half-remembered note
        // itself, findable only by its tag, not by a guessed keyword.
        createFixtureDocument(app: app, notebookDocuments: notebookDocuments, title: "Today's Entry", content: "Writing about the new onboarding flow.")
        createFixtureDocument(app: app, notebookDocuments: notebookDocuments, title: "Elena's Sketch", content: "An early mockup for a guided setup wizard.\n\n#onboarding-idea ")

        // A[Tries a guessed keyword] -> B{Misses — no literal-substring match in either note}
        MainShellScreen(app: app).navigate(to: "Search")
        let search = SearchScreen(app: app)
        XCTAssertTrue(search.navigationTitle.waitForExistence(timeout: 5))
        search.searchField.tap()
        search.searchField.typeText("onboarding wizard")
        XCTAssertFalse(app.element(labeledContaining: "Elena's Sketch").exists)
        XCTAssertFalse(app.element(labeledContaining: "Today's Entry").exists)

        // C[Opens the current note's local graph] -> D{Miss — not linked, so not there}
        // Switching tabs immediately after typing into a field is unreliable under XCUITest's
        // synthesized-event timing (see `Phase2TaskDashboardAndSavedViewsFeatureTests`'s note)
        // — confirmed here too, not just after the journal's day-navigation round trip.
        sleep(3)
        MainShellScreen(app: app).navigate(to: "Notebooks")
        notebookRow.tap()
        let todayEntryRow = notebookDocuments.documentRow(title: "Today's Entry")
        XCTAssertTrue(todayEntryRow.waitForExistence(timeout: 5))
        todayEntryRow.tap()

        let todayEntryDocument = DocumentScreen(app: app)
        XCTAssertTrue(todayEntryDocument.graphButton.waitForExistence(timeout: 5))
        todayEntryDocument.graphButton.tap()
        let graph = GraphScreen(app: app)
        XCTAssertTrue(graph.zoomInButton.waitForExistence(timeout: 5))
        XCTAssertFalse(app.element(labeledContaining: "Elena's Sketch").exists)
        app.dismissSheetByDragging()
        XCTAssertTrue(graph.zoomInButton.waitForNonExistence(timeout: 5))

        // E[Falls back to the Tag Browser] -> F[Finds it by its tag]. Reached via the tag chip
        // on Elena's Sketch itself (S13 has no compact-width tab/sidebar slot — see Phase 1).
        app.navigationBars.buttons["BackButton"].tap() // Today's Entry -> Journey4 Fixture
        let elenaRow = notebookDocuments.documentRow(title: "Elena's Sketch")
        XCTAssertTrue(elenaRow.waitForExistence(timeout: 5))
        elenaRow.tap()

        let elenaDocument = DocumentScreen(app: app)
        let tagChip = app.button(labeled: "#onboarding-idea")
        XCTAssertTrue(tagChip.waitForExistence(timeout: 5))
        tagChip.tap()

        let tagBrowser = TagBrowserScreen(app: app)
        XCTAssertTrue(tagBrowser.navigationTitle.waitForExistence(timeout: 5))
        let tagRow = tagBrowser.tagRow(name: "onboarding-idea")
        XCTAssertTrue(tagRow.waitForExistence(timeout: 5))
        tagRow.tap()
        XCTAssertTrue(app.element(labeledContaining: "Elena's Sketch").waitForExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].tap() // tagged-documents -> Tag Browser
        app.dismissSheetByDragging() // Tag Browser sheet -> Elena's Sketch

        // G[Closes the loop]: links today's note to the rediscovered one.
        XCTAssertTrue(elenaDocument.titleField.waitForExistence(timeout: 5))
        app.navigationBars.buttons["BackButton"].tap() // Elena's Sketch -> Journey4 Fixture
        XCTAssertTrue(todayEntryRow.waitForExistence(timeout: 5))
        todayEntryRow.tap()

        XCTAssertTrue(todayEntryDocument.titleField.waitForExistence(timeout: 5))
        todayEntryDocument.enterEditMode()
        XCTAssertTrue(todayEntryDocument.contentEditor.waitForExistence(timeout: 5))
        todayEntryDocument.contentEditor.tap()
        todayEntryDocument.contentEditor.typeText("\nRelated: [[Elena's Sketch]]")
        app.navigationBars.buttons["BackButton"].tap() // Today's Entry -> Journey4 Fixture

        // Elena's Sketch's Backlinks pane now shows the link back — the loop is closed.
        XCTAssertTrue(elenaRow.waitForExistence(timeout: 5))
        elenaRow.tap()
        XCTAssertTrue(elenaDocument.backlinksButton.waitForExistence(timeout: 5))
        elenaDocument.backlinksButton.tap()
        let backlinks = BacklinksPaneScreen(app: app)
        XCTAssertTrue(backlinks.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(labeledContaining: "Today's Entry").waitForExistence(timeout: 5))
    }

}
