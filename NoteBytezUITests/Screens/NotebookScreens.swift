// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookScreens.swift
//  KontinuumUITests
//

import XCTest

/// S14 — Notebook Browser.
struct NotebookBrowserScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Notebooks"] }
    var newNotebookButton: XCUIElement { app.button(labeled: "New Notebook") }
    /// The toolbar's `.secondaryAction`-placed Canvas link — on iPhone's compact nav bar this
    /// collapses into the "More" overflow button rather than showing directly, so this always
    /// opens the overflow first if the direct button isn't already visible.
    var canvasButton: XCUIElement {
        let direct = app.button(labeled: "Canvas")
        if direct.waitForExistence(timeout: 1) { return direct }
        let overflow = app.buttons["More"]
        if overflow.waitForExistence(timeout: 2) { overflow.tap() }
        return app.button(labeled: "Canvas")
    }

    func notebookRow(name: String) -> XCUIElement {
        app.element(labeledContaining: name)
    }

    @discardableResult
    func createNotebook(named name: String) -> Self {
        XCTAssertTrue(newNotebookButton.waitForExistence(timeout: 5))
        newNotebookButton.tap()

        let nameField = app.textFields["Notebook Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        app.buttons["primaryButton.Create"].tap()
        return self
    }

}

/// Documents filed into a notebook — the S14 drill-down destination.
struct NotebookDocumentsScreen {

    let app: XCUIApplication

    var newNoteButton: XCUIElement { app.button(labeled: "New Note") }

    func documentRow(title: String) -> XCUIElement {
        app.button(labeled: title)
    }

}

/// S15 — Promote to Notebook, and its entry-point block picker.
struct PromoteBlockPickerScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Promote a Block"] }
    var cancelButton: XCUIElement { app.button(labeled: "Cancel") }

    func blockRow(containing text: String) -> XCUIElement {
        app.element(labeledContaining: text)
    }

}

struct PromoteToNotebookScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Promote to Notebook"] }
    var newNotebookNameField: XCUIElement { app.textFields["Notebook Name"] }
    var promoteButton: XCUIElement { app.button(labeled: "Promote") }
    var cancelButton: XCUIElement { app.button(labeled: "Cancel") }

}
