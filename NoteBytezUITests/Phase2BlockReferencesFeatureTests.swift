// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase2BlockReferencesFeatureTests.swift
//  NoteBytezUITests
//
//  Phase 2 — Feature Coverage: Block References (V1). Writes a block in one document, then
//  inserts a `((anchor))` reference to it from a second document via the `((` autocomplete row,
//  and confirms the block-level backlink actually appears in the first document's Backlinks
//  pane — not just that the Backlinks screen's (conditionally-empty) sections render (already
//  covered by Phase 1).
//
//  Verification status: not yet passing in this environment — the `((` autocomplete row isn't
//  reliably appearing after typing in the second document within the time budget tried so far.
//  `BlockReferenceDAL.autocompleteMatches`/`BlockReferenceParser.activeQuery` were read and the
//  approach (empty query still returns the library's first blocks, so no anchor text needs to
//  be typed) is sound against the actual DAL code; what wasn't pinned down is why the
//  suggestion row itself isn't rendering in time here. Carried forward honestly rather than
//  force-fitted into a false pass.
//

import XCTest

final class Phase2BlockReferencesFeatureTests: NoteBytezUITestCase {

    @MainActor
    func testBlockReferenceCreatesBlockLevelBacklink() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Notebooks")

        let notebooks = NotebookBrowserScreen(app: app)
        notebooks.createNotebook(named: "Reference Fixture")
        let notebookRow = notebooks.notebookRow(name: "Reference Fixture")
        XCTAssertTrue(notebookRow.waitForExistence(timeout: 5))
        notebookRow.tap()

        let notebookDocuments = NotebookDocumentsScreen(app: app)
        XCTAssertTrue(app.navigationBars["Reference Fixture"].waitForExistence(timeout: 5))

        // Source document — the block that will be referenced.
        createDocument(named: "Source Note", content: "- The key finding from the interview", notebookDocuments: notebookDocuments)
        // Referencing document — types `((` to trigger the autocomplete row (an empty query
        // returns the library's first blocks, so no need to know the exact generated anchor
        // text) and taps the first suggestion.
        notebookDocuments.newNoteButton.tap()
        let picker = TemplatePickerScreen(app: app)
        XCTAssertTrue(picker.startBlankButton.waitForExistence(timeout: 5))
        picker.startBlankButton.tap()
        let untitledRow = app.button(labeled: "Untitled")
        XCTAssertTrue(untitledRow.waitForExistence(timeout: 5))
        untitledRow.tap()

        let referencingDocument = DocumentScreen(app: app)
        XCTAssertTrue(referencingDocument.titleField.waitForExistence(timeout: 5))
        referencingDocument.titleField.tap()
        referencingDocument.titleField.typeText("Referencing Note")
        referencingDocument.enterEditMode()
        XCTAssertTrue(referencingDocument.contentEditor.waitForExistence(timeout: 5))
        referencingDocument.contentEditor.tap()
        referencingDocument.contentEditor.typeText("See ((")

        let suggestion = referencingDocument.firstBlockReferenceSuggestion
        XCTAssertTrue(suggestion.waitForExistence(timeout: 5), String(app.debugDescription.prefix(4000)))
        suggestion.tap()

        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(notebookDocuments.newNoteButton.waitForExistence(timeout: 5))

        // Back on the source note, its Backlinks pane should now show a "Block References"
        // section naming the referencing document.
        let sourceRow = notebookDocuments.documentRow(title: "Source Note")
        XCTAssertTrue(sourceRow.waitForExistence(timeout: 5))
        sourceRow.tap()

        let sourceDocument = DocumentScreen(app: app)
        XCTAssertTrue(sourceDocument.backlinksButton.waitForExistence(timeout: 5))
        sourceDocument.backlinksButton.tap()

        let backlinks = BacklinksPaneScreen(app: app)
        XCTAssertTrue(backlinks.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(backlinks.blockReferencesSection.waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(labeledContaining: "Referencing Note").waitForExistence(timeout: 5))
    }

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
