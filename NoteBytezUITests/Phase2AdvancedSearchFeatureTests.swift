// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase2AdvancedSearchFeatureTests.swift
//  NoteBytezUITests
//
//  Phase 2 — Feature Coverage: Advanced Search (V1). Creates two real documents with distinct
//  tag combinations, then confirms a boolean `#tag AND #tag` query actually narrows results to
//  the one matching both — not just that the advanced-mode toggle and hint text render (already
//  covered by Phase 1).
//

import XCTest

final class Phase2AdvancedSearchFeatureTests: NoteBytezUITestCase {

    @MainActor
    func testBooleanTagQueryNarrowsToMatchingDocument() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Notebooks")

        let notebooks = NotebookBrowserScreen(app: app)
        notebooks.createNotebook(named: "Search Fixture")
        let notebookRow = notebooks.notebookRow(name: "Search Fixture")
        XCTAssertTrue(notebookRow.waitForExistence(timeout: 5))
        notebookRow.tap()

        let notebookDocuments = NotebookDocumentsScreen(app: app)
        XCTAssertTrue(app.navigationBars["Search Fixture"].waitForExistence(timeout: 5))

        createDocument(named: "Urgent Task", content: "- Fix the login bug #project #urgent", notebookDocuments: notebookDocuments)
        createDocument(named: "Regular Notes", content: "- General planning #project", notebookDocuments: notebookDocuments)

        MainShellScreen(app: app).navigate(to: "Search")
        let search = SearchScreen(app: app)
        XCTAssertTrue(search.navigationTitle.waitForExistence(timeout: 5))
        search.advancedModeToggleOff.tap()
        XCTAssertTrue(search.advancedModeToggleOn.waitForExistence(timeout: 5))

        let advancedField = search.advancedFieldPlaceholder
        XCTAssertTrue(advancedField.waitForExistence(timeout: 5))
        advancedField.tap()
        advancedField.typeText("#project AND #urgent")

        XCTAssertTrue(app.element(labeledContaining: "Urgent Task").waitForExistence(timeout: 5))
        XCTAssertFalse(app.element(labeledContaining: "Regular Notes").exists)
    }

    /// Creates a document from the current `NotebookDocumentsScreen`, titles it, writes
    /// `content`, and navigates back (saving via `DocumentView`'s own `.onDisappear`).
    @MainActor
    private func createDocument(named title: String, content: String, notebookDocuments: NotebookDocumentsScreen) {
        notebookDocuments.newNoteButton.tap()
        let picker = TemplatePickerScreen(app: app)
        XCTAssertTrue(picker.startBlankButton.waitForExistence(timeout: 5))
        picker.startBlankButton.tap()

        let untitledRow = app.button(labeled: "Untitled")
        XCTAssertTrue(untitledRow.waitForExistence(timeout: 5))
        untitledRow.tap()

        let document = DocumentScreen(app: app)
        XCTAssertTrue(document.titleField.waitForExistence(timeout: 5))
        document.titleField.tap()
        document.titleField.typeText(title)

        document.enterEditMode()
        XCTAssertTrue(document.contentEditor.waitForExistence(timeout: 5))
        document.contentEditor.tap()
        document.contentEditor.typeText(content)

        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(notebookDocuments.newNoteButton.waitForExistence(timeout: 5))
    }

}
