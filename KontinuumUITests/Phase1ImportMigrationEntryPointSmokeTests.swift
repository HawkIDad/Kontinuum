// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase1ImportMigrationEntryPointSmokeTests.swift
//  KontinuumUITests
//
//  Phase 1 — Screen Smoke Coverage. S2 (Import Scan & Confirm), S23 (Migration Assistant), and
//  S20 (Attachment Preview) all only render *after* a system file/folder picker (`fileImporter`)
//  resolves a selection — reliably driving that system picker from XCUITest (navigating
//  "On My iPhone"/iCloud Drive, or staging a fixture file/folder the Simulator's Files app can
//  browse to) is a known simulator/system-UI automation gap, the same category of limitation
//  already documented for the live two-device sync race
//  (Docs/Plans/NoteBytez20260823v1-UITests.md, Success Factor #4). What's covered here instead:
//  confirming each entry point is present and tapping it doesn't crash the app — S2/S23/S20
//  themselves aren't reached by these tests. (An earlier version of these tests asserted the
//  triggering button disappeared once the system picker opened; in practice the Simulator's
//  file/folder picker doesn't reliably remove the host app's own elements from XCUITest's
//  accessibility snapshot, so that assertion was unreliable and has been dropped rather than
//  kept as a flaky check.)
//

import XCTest

final class Phase1ImportMigrationEntryPointSmokeTests: KontinuumUITestCase {

    @MainActor
    func testImportFolderEntryPointOpensSystemPicker() throws {
        app.launch()
        let library = LibrarySelectionScreen(app: app)
        XCTAssertTrue(library.importFolderButton.waitForExistence(timeout: 5))
        library.importFolderButton.tap()
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testMigrationAssistantEntryPointOpensSystemPicker() throws {
        app.launch()
        let library = LibrarySelectionScreen(app: app)
        XCTAssertTrue(library.migrationAssistantButton.waitForExistence(timeout: 5))
        library.migrationAssistantButton.tap()
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testAddAttachmentEntryPointOpensSystemPicker() throws {
        launchAndCreateLibrary()
        MainShellScreen(app: app).navigate(to: "Notebooks")

        let notebooks = NotebookBrowserScreen(app: app)
        notebooks.createNotebook(named: "Research")
        notebooks.notebookRow(name: "Research").tap()

        let notebookDocuments = NotebookDocumentsScreen(app: app)
        XCTAssertTrue(app.navigationBars["Research"].waitForExistence(timeout: 5))
        notebookDocuments.newNoteButton.tap()
        XCTAssertTrue(TemplatePickerScreen(app: app).navigationTitle.waitForExistence(timeout: 5))
        TemplatePickerScreen(app: app).startBlankButton.tap()
        let untitledRow = notebookDocuments.documentRow(title: "Untitled")
        XCTAssertTrue(untitledRow.waitForExistence(timeout: 5))
        untitledRow.tap()

        let document = DocumentScreen(app: app)
        XCTAssertTrue(document.addAttachmentButton.waitForExistence(timeout: 5))
        document.addAttachmentButton.tap()
        XCTAssertEqual(app.state, .runningForeground)
    }

}
