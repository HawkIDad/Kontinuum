// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentScreens.swift
//  KontinuumUITests
//

import XCTest

/// S3 — Today (Journal).
struct TodayJournalScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Today"] }
    var editor: XCUIElement { app.textViews.firstMatch }
    var previousDayButton: XCUIElement { app.button(labeled: "Previous day") }
    var nextDayButton: XCUIElement { app.button(labeled: "Next day") }
    var quickSwitcherButton: XCUIElement { app.button(labeled: "Quick Switcher") }
    var promoteButton: XCUIElement { app.button(labeled: "Promote to Notebook") }
    var tasksButton: XCUIElement { app.button(labeled: "Tasks") }

    /// Types `text` into the journal body, then round-trips through Previous/Next day
    /// navigation — the one reliable way to force `DocumentViewModel.save()` (and therefore
    /// tag/block/task parsing) to run without leaving S3 entirely, since typing alone only
    /// mutates the in-memory `content` binding. Previous-then-Next, not Next-then-Previous: the
    /// Next button is disabled while already on today (`JournalDayHeader`'s own "never moves
    /// into the future" rule), so a Next-first round trip would silently no-op and strand the
    /// test on yesterday's (empty) entry instead of saving and returning to today's.
    @discardableResult
    func writeAndPersist(_ text: String) -> Self {
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.tap()
        editor.typeText(text)
        previousDayButton.tap()
        nextDayButton.tap()
        return self
    }

}

/// S4 — Document (Note) View, and S17 — Properties Editor (inline within it).
struct DocumentScreen {

    let app: XCUIApplication

    var titleField: XCUIElement { app.textFields["Title"] }
    /// The single Edit/Preview toggle button — its label flips between the two states.
    var editButton: XCUIElement { app.button(labeled: "Edit") }
    var previewButton: XCUIElement { app.button(labeled: "Preview") }
    var exportButton: XCUIElement { app.button(labeled: "Export") }
    var backlinksButton: XCUIElement { app.button(labeled: "Backlinks") }
    /// Excludes the persistent tab bar's own "Graph" destination (identifier `tabbar.Graph`) —
    /// a plain label match is ambiguous when this screen is reached by a `NavigationStack` push
    /// inside a `TabView` tab (iPhone), which stays mounted underneath.
    var graphButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", "Graph", "tabbar.Graph")).firstMatch
    }
    var applyTemplateButton: XCUIElement { app.button(labeled: "Apply Template") }
    var addAttachmentButton: XCUIElement { app.button(labeled: "Add Attachment") }

    /// Switches into edit mode (Edit -> Preview label flip) if not already there, so S17's
    /// property-add row and the raw Markdown `TextEditor` become visible.
    @discardableResult
    func enterEditMode() -> Self {
        if editButton.exists { editButton.tap() }
        return self
    }

    // S17 — Properties Editor (only visible once `editToggleButton` has been tapped, or an
    // existing property is already present).
    var propertyNameField: XCUIElement { app.textFields["Property name"] }
    var addPropertyButton: XCUIElement { app.button(labeled: "Add") }

    var contentEditor: XCUIElement { app.textViews.firstMatch }

    /// The first `((anchor))` suggestion chip in the block-reference autocomplete row —
    /// `BlockReferenceDAL.autocompleteMatches` returns the library's first blocks for an empty
    /// query, so typing just `((` (no anchor text) is enough to reveal at least one.
    var firstBlockReferenceSuggestion: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "((")).firstMatch
    }

}

/// S5 — Backlinks Pane.
struct BacklinksPaneScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Backlinks"] }
    var linkedMentionsSection: XCUIElement { app.element(labeled: "Linked Mentions") }
    var unlinkedMentionsSection: XCUIElement { app.element(labeled: "Unlinked Mentions") }
    /// Only present once `viewModel.blockBacklinks` is non-empty.
    var blockReferencesSection: XCUIElement { app.element(labeled: "Block References") }

}

/// "All Notes" — sidebar-only entry point into S4 (Mac/iPad regular width; no iPhone tab bar
/// slot per `ContentView.AppDestination.tabBarDestinations`).
struct DocumentListScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["All Notes"] }
    var newNoteButton: XCUIElement { app.button(labeled: "New Note") }

}
