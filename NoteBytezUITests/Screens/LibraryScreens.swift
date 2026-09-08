// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LibraryScreens.swift
//  KontinuumUITests
//

import XCTest

/// S1 — Library Creation / Selection.
struct LibrarySelectionScreen {

    let app: XCUIApplication

    var createNewLibraryButton: XCUIElement { app.buttons["primaryButton.Create New Library"] }
    var importFolderButton: XCUIElement { app.button(labeled: "Import Existing Markdown Folder") }
    var migrationAssistantButton: XCUIElement { app.button(labeled: "Migration Assistant (Obsidian/Logseq)") }

    @discardableResult
    func createLibrary(named name: String) -> Self {
        XCTAssertTrue(createNewLibraryButton.waitForExistence(timeout: 5))
        createNewLibraryButton.tap()

        let nameField = app.textFields["Library Name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)

        app.buttons["primaryButton.Create"].tap()
        return self
    }

}
