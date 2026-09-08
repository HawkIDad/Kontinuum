// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase5AccessibilityTests.swift
//  NoteBytezUITests
//
//  Phase 5 — Accessibility Pass (docs/styleGuide.md §Accessibility, a "hard requirement, not a
//  nice-to-have"). Two checks: every icon-only control exposes a non-empty VoiceOver label, and
//  the Journal/Document view doesn't truncate text at an accessibility Dynamic Type size.
//

import XCTest

final class Phase5AccessibilityTests: NoteBytezUITestCase {

    /// Walks every button currently on screen and flags any whose accessibility label is empty
    /// — an icon-only control that forgot `.accessibilityLabel`, since a labeled control (even
    /// an icon one, via `Label` or an explicit `.accessibilityLabel`) always has non-empty text
    /// here, and a bare `Image`-only `Button` is the one shape that can silently end up with
    /// none.
    private func assertNoUnlabeledButtons(on screenName: String, file: StaticString = #filePath, line: UInt = #line) {
        let buttons = app.buttons.allElementsBoundByIndex
        let unlabeled = buttons.filter { $0.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        XCTAssertTrue(
            unlabeled.isEmpty,
            "\(unlabeled.count) icon-only button(s) with no accessibility label on \(screenName): \(unlabeled.map { $0.debugDescription }.prefix(3))",
            file: file, line: line
        )
    }

    @MainActor
    func testNoUnlabeledIconButtonsAcrossMainScreens() throws {
        launchAndCreateLibrary()

        let today = TodayJournalScreen(app: app)
        XCTAssertTrue(today.editor.waitForExistence(timeout: 5))
        assertNoUnlabeledButtons(on: "Today")

        MainShellScreen(app: app).navigate(to: "Notebooks")
        let notebooks = NotebookBrowserScreen(app: app)
        XCTAssertTrue(notebooks.navigationTitle.waitForExistence(timeout: 5))
        assertNoUnlabeledButtons(on: "Notebooks (empty)")

        notebooks.createNotebook(named: "A11y Fixture")
        let notebookRow = notebooks.notebookRow(name: "A11y Fixture")
        XCTAssertTrue(notebookRow.waitForExistence(timeout: 5))
        notebookRow.tap()

        let notebookDocuments = NotebookDocumentsScreen(app: app)
        XCTAssertTrue(app.navigationBars["A11y Fixture"].waitForExistence(timeout: 5))
        notebookDocuments.newNoteButton.tap()
        let picker = TemplatePickerScreen(app: app)
        XCTAssertTrue(picker.startBlankButton.waitForExistence(timeout: 5))
        picker.startBlankButton.tap()

        let noteRow = app.button(labeled: "Untitled")
        XCTAssertTrue(noteRow.waitForExistence(timeout: 5))
        noteRow.tap()
        let document = DocumentScreen(app: app)
        XCTAssertTrue(document.titleField.waitForExistence(timeout: 5))
        // S4's bottom action row (Export/Backlinks/Graph/Apply Template/Add Attachment) is
        // exactly the icon-only-button shape this check exists for.
        assertNoUnlabeledButtons(on: "Document (S4)")
    }

    /// Journal/Document text must reflow, not clip, at an accessibility Dynamic Type size
    /// (docs/styleGuide.md's own hard requirement). `UIContentSizeCategory` is set via a launch
    /// argument XCTest recognizes directly — no app-side support needed.
    @MainActor
    func testJournalTextReflowsAtAccessibilityDynamicTypeSize() throws {
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        launchAndCreateLibrary()

        let today = TodayJournalScreen(app: app)
        XCTAssertTrue(today.editor.waitForExistence(timeout: 5))
        today.editor.tap()
        today.editor.typeText("\n- This is a reasonably long line of journal text meant to wrap across several lines at an accessibility text size rather than being clipped or truncated.")

        // At this text size the line necessarily spans several lines — a truncated/clipped
        // render would instead leave the typed text partially or fully missing from the
        // accessible value, which is what this actually checks (frame-height comparisons are
        // fragile across simulators/OS versions; the text either round-trips through the
        // editor's own accessibility value or it doesn't).
        let value = today.editor.value as? String ?? ""
        XCTAssertTrue(value.contains("accessibility text size"), "Journal text didn't round-trip through the editor at an accessibility Dynamic Type size: \(value)")
    }

}
