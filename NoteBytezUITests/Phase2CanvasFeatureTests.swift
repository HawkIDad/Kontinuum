// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase2CanvasFeatureTests.swift
//  NoteBytezUITests
//
//  Phase 2 — Feature Coverage: Canvas (V1). Creates a board, adds a note card that references a
//  real existing document, and adds a group card — confirming both actually appear on the board
//  afterward, not just that the empty board/add-card menu render (already covered by Phase 1).
//
//  Verification status: not yet passing in this environment — the "Add Note" candidate-row tap
//  isn't reliably landing (the board is observed back in its pre-add state afterward, with no
//  error from the tap itself). Carried forward honestly rather than force-fitted into a false
//  pass; `CanvasViewModel.noteCardCandidates(matching:)` was confirmed to return the fixture
//  document for an empty query, so the DAL side isn't the issue.
//

import XCTest

final class Phase2CanvasFeatureTests: NoteBytezUITestCase {

    @MainActor
    func testAddNoteCardAndGroupCardAppearOnBoard() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Notebooks")

        let notebooks = NotebookBrowserScreen(app: app)
        notebooks.createNotebook(named: "Canvas Fixture")
        let notebookRow = notebooks.notebookRow(name: "Canvas Fixture")
        XCTAssertTrue(notebookRow.waitForExistence(timeout: 5))
        notebookRow.tap()

        // A real document for the note card to reference.
        let notebookDocuments = NotebookDocumentsScreen(app: app)
        XCTAssertTrue(app.navigationBars["Canvas Fixture"].waitForExistence(timeout: 5))
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
        document.titleField.typeText("Suspect Profile")
        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(notebookDocuments.newNoteButton.waitForExistence(timeout: 5))

        // Canvas: reached via the Notebooks toolbar (no dedicated iPhone tab).
        MainShellScreen(app: app).navigate(to: "Notebooks")
        XCTAssertTrue(notebooks.canvasButton.waitForExistence(timeout: 5))
        notebooks.canvasButton.tap()

        let boardList = CanvasBoardListScreen(app: app)
        XCTAssertTrue(boardList.navigationTitle.waitForExistence(timeout: 5))
        boardList.createBoard(named: "Mystery Board")
        let boardRow = boardList.boardRow(name: "Mystery Board")
        XCTAssertTrue(boardRow.waitForExistence(timeout: 5))
        boardRow.tap()

        let board = CanvasBoardScreen(app: app)
        XCTAssertTrue(board.addCardButton.waitForExistence(timeout: 5))
        board.addCardButton.tap()
        XCTAssertTrue(board.addNoteMenuItem.waitForExistence(timeout: 5))
        board.addNoteMenuItem.tap()

        XCTAssertTrue(board.addNoteSearchField.waitForExistence(timeout: 5))
        let candidateRow = board.addNoteDocumentRow(title: "Suspect Profile")
        XCTAssertTrue(candidateRow.waitForExistence(timeout: 5), String(app.debugDescription.prefix(4000)))
        candidateRow.tap()

        XCTAssertTrue(board.card(labeledContaining: "Suspect Profile").waitForExistence(timeout: 5))

        // A group card, added the same way.
        board.addCardButton.tap()
        XCTAssertTrue(board.addGroupMenuItem.waitForExistence(timeout: 5))
        board.addGroupMenuItem.tap()

        let groupLabelField = app.textFields["Label"]
        XCTAssertTrue(groupLabelField.waitForExistence(timeout: 5))
        groupLabelField.tap()
        groupLabelField.typeText("Act 1")
        app.alerts.buttons["Add"].tap()

        XCTAssertTrue(board.card(labeledContaining: "Act 1").waitForExistence(timeout: 5))
    }

}
