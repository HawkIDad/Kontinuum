// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentFixtures.swift
//  NoteBytezUITests
//

import XCTest

/// Shared "create a titled document with body content inside the current Notebook" flow —
/// duplicated inline across enough Phase 2/3 tests (`Phase2AdvancedSearchFeatureTests`,
/// `Phase2BlockReferencesFeatureTests`, `Phase2CanvasFeatureTests`) that it's worth one shared
/// helper for the tests written after it, rather than a fourth copy-paste.
extension XCTestCase {

    /// From the current `NotebookDocumentsScreen`: "+" -> Start Blank -> tap the resulting
    /// "Untitled" row -> set title -> (optionally) write body content -> back. Leaves the app on
    /// `NotebookDocumentsScreen` again, with `newNoteButton` confirmed visible.
    @MainActor
    func createFixtureDocument(app: XCUIApplication, notebookDocuments: NotebookDocumentsScreen, title: String, content: String? = nil) {
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

        if let content {
            document.enterEditMode()
            XCTAssertTrue(document.contentEditor.waitForExistence(timeout: 5))
            document.contentEditor.tap()
            document.contentEditor.typeText(content)
        }

        app.navigationBars.buttons["BackButton"].tap()
        XCTAssertTrue(notebookDocuments.newNoteButton.waitForExistence(timeout: 5))
    }

}
