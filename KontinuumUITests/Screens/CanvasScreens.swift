// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasScreens.swift
//  KontinuumUITests
//

import XCTest

/// Library-scoped Canvas board list — reached via `NotebookBrowserScreen.canvasButton` on every
/// platform (Canvas has no dedicated iPhone tab per `05-Wireframes.md`'s S16 note).
struct CanvasBoardListScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Canvas"] }
    var newBoardButton: XCUIElement { app.button(labeled: "New Board") }
    var importCanvasButton: XCUIElement { app.button(labeled: "Import Canvas…") }

    func boardRow(name: String) -> XCUIElement {
        app.element(labeledContaining: name)
    }

    @discardableResult
    func createBoard(named name: String) -> Self {
        XCTAssertTrue(newBoardButton.waitForExistence(timeout: 5))
        newBoardButton.tap()

        let nameField = app.textFields["Board Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        app.buttons["primaryButton.Create"].tap()
        return self
    }

}

/// S16 — Canvas board itself.
struct CanvasBoardScreen {

    let app: XCUIApplication

    var addCardButton: XCUIElement { app.button(labeled: "Add Card") }
    var connectCardsButton: XCUIElement { app.button(labeled: "Connect Cards") }
    var zoomInButton: XCUIElement { app.button(labeled: "Zoom In") }
    var zoomOutButton: XCUIElement { app.button(labeled: "Zoom Out") }
    var fitToScreenButton: XCUIElement { app.button(labeled: "Fit to Screen") }
    var addWebLinkMenuItem: XCUIElement { app.button(labeled: "Add Web Link…") }
    var addGroupMenuItem: XCUIElement { app.button(labeled: "Add Group…") }
    var addNoteMenuItem: XCUIElement { app.button(labeled: "Add Note…") }

    // "Add Note" sheet — `.searchable()` produces a `XCUIElementTypeSearchField`, not a plain
    // `TextField`.
    var addNoteSearchField: XCUIElement { app.searchFields["Search notes"] }
    func addNoteDocumentRow(title: String) -> XCUIElement { app.button(labeled: title) }

    func card(labeledContaining text: String) -> XCUIElement { app.element(labeledContaining: text) }

}
