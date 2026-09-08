// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase1NotebookDocumentSmokeTests.swift
//  NoteBytezUITests
//
//  Phase 1 — Screen Smoke Coverage. Covers S14 (Notebook Browser), S18's Picker sub-flow, S4
//  (Document View), S17 (Properties Editor, inline in S4), S5 (Backlinks Pane), S8 (Graph, from
//  S4's toolbar), and S16 (Canvas — list + board), reached the way a real user reaches them: via
//  Notebooks, since neither "All Notes" nor a bare document-creation entry point exists on
//  iPhone's compact tab bar (see `ContentView.AppDestination.tabBarDestinations`).
//

import XCTest

final class Phase1NotebookDocumentSmokeTests: NoteBytezUITestCase {

    @MainActor
    func testNotebookDocumentPropertiesAndBacklinksFlowRenders() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Notebooks")

        let notebooks = NotebookBrowserScreen(app: app)
        notebooks.createNotebook(named: "Research")
        let notebookRow = notebooks.notebookRow(name: "Research")
        XCTAssertTrue(notebookRow.waitForExistence(timeout: 5))
        notebookRow.tap()

        let notebookDocuments = NotebookDocumentsScreen(app: app)
        XCTAssertTrue(app.navigationBars["Research"].waitForExistence(timeout: 5))
        XCTAssertTrue(notebookDocuments.newNoteButton.waitForExistence(timeout: 5))
        notebookDocuments.newNoteButton.tap()

        let templatePicker = TemplatePickerScreen(app: app)
        XCTAssertTrue(templatePicker.navigationTitle.waitForExistence(timeout: 5), String(app.debugDescription.prefix(4000)))
        XCTAssertTrue(templatePicker.startBlankButton.exists)
        templatePicker.startBlankButton.tap()

        let untitledRow = notebookDocuments.documentRow(title: "Untitled")
        XCTAssertTrue(untitledRow.waitForExistence(timeout: 5))
        untitledRow.tap()

        // S4 — Document View
        let document = DocumentScreen(app: app)
        XCTAssertTrue(document.titleField.waitForExistence(timeout: 5))
        XCTAssertTrue(document.backlinksButton.exists)
        XCTAssertTrue(document.graphButton.exists)
        XCTAssertTrue(document.applyTemplateButton.exists)
        XCTAssertTrue(document.addAttachmentButton.exists)

        // S17 — Properties Editor (inline, only visible once editing)
        document.enterEditMode()
        XCTAssertTrue(document.propertyNameField.waitForExistence(timeout: 5))
        document.propertyNameField.tap()
        document.propertyNameField.typeText("Species")
        document.addPropertyButton.tap()

        // S5 — Backlinks Pane (sheet; no explicit dismiss control, per `BacklinksPaneView`)
        document.backlinksButton.tap()
        let backlinks = BacklinksPaneScreen(app: app)
        XCTAssertTrue(backlinks.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(backlinks.linkedMentionsSection.exists)
        XCTAssertTrue(backlinks.unlinkedMentionsSection.exists)
        app.dismissSheetByDragging()
        // Confirms the sheet actually finished dismissing before the next step — a swipe alone
        // can still be mid-animation when the next query runs, ambiguously tapping through to
        // whatever's still transitioning underneath.
        XCTAssertTrue(backlinks.navigationTitle.waitForNonExistence(timeout: 5))

        // S8 — Graph, opened from S4's toolbar (sheet; no explicit dismiss control)
        XCTAssertTrue(document.graphButton.waitForExistence(timeout: 5))
        document.graphButton.tap()
        let graph = GraphScreen(app: app)
        XCTAssertTrue(graph.zoomInButton.waitForExistence(timeout: 5), String(app.debugDescription.prefix(3000)))
        app.dismissSheetByDragging()
    }

    @MainActor
    func testCanvasBoardListAndBoardRender() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Notebooks")

        let notebooks = NotebookBrowserScreen(app: app)
        XCTAssertTrue(notebooks.canvasButton.waitForExistence(timeout: 5))
        notebooks.canvasButton.tap()

        let boardList = CanvasBoardListScreen(app: app)
        XCTAssertTrue(boardList.navigationTitle.waitForExistence(timeout: 5))
        boardList.createBoard(named: "Plot Board")

        let boardRow = boardList.boardRow(name: "Plot Board")
        XCTAssertTrue(boardRow.waitForExistence(timeout: 5))
        boardRow.tap()

        let board = CanvasBoardScreen(app: app)
        XCTAssertTrue(board.addCardButton.waitForExistence(timeout: 5))
        XCTAssertTrue(board.connectCardsButton.exists)
        XCTAssertTrue(board.zoomInButton.exists)
        XCTAssertTrue(board.zoomOutButton.exists)
        XCTAssertTrue(board.fitToScreenButton.exists)
    }

}
