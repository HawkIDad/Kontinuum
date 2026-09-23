// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  WebsiteScreenshotTests.swift
//  NoteBytezUITests
//

import XCTest

/// iPhone flows for the website screenshots (see `WebsiteScreenshotCase`). Not a regression test:
/// it skips unless `WEBSITE_SCREENSHOTS=1`; `WebSite/tools/screenshots/capture-ui.sh` runs it.
#if os(iOS)
final class WebsiteScreenshotTests: WebsiteScreenshotCase {

    // MARK: - Flows (one launch per flow, several screens each)

    func testGettingStartedFlow() {
        launchEmpty()
        shoot("getting-started", "library-picker")
        app.buttons["primaryButton.Create New Library"].tap()
        shoot("getting-started", "create-library-sheet")
        let nameField = app.textFields["newLibrary.nameField"]
        guard nameField.waitForExistence(timeout: 5) else { return }
        nameField.tap()
        nameField.typeText("My Library")
        app.buttons["primaryButton.Create"].tap()
        if app.navigationBars["What do you use NoteBytez for?"].waitForExistence(timeout: 8) {
            shoot("getting-started", "role-picker")
        }
    }

    func testJournalAndPromoteFlow() {
        launchSeeded()
        shoot("capture-and-journal", "todays-journal")
        type("A new idea worth its own note", into: app.textViews.firstMatch)
        // Preview hides the keyboard; leaving the screen then saves the entry so the picker can list its blocks.
        app.button(labeled: "Preview").tap()
        openTab("Notebooks")
        openTab("Today")
        app.button(labeled: "Quick Switcher").tap()
        shoot("search-and-navigation", "quick-switcher")
        app.button(labeled: "Cancel").tap()
        app.button(labeled: "Tasks").tap()
        shoot("tasks", "tasks-sheet")
        dismissSheet()
        app.button(labeled: "Promote to Notebook").tap()
        shoot("notebooks", "promote-block-picker")
        app.element(labeledContaining: "A new idea worth").tap()
        shoot("notebooks", "promote-to-notebook")
    }

    func testNotesAndLinkingFlow() {
        launchSeeded()
        openTab("Notebooks")
        shoot("notebooks", "notebook-browser")
        app.button(labeled: "New Notebook").tap()
        shoot("notebooks", "new-notebook-sheet")
        app.button(labeled: "Cancel").tap()
        app.staticTexts["Projects"].firstMatch.tap()
        shoot("notebooks", "notebook-documents")
        app.button(labeled: "New Note").tap()
        shoot("documents-and-blocks", "template-picker")
        app.button(labeled: "Cancel").tap()
        app.staticTexts["Project Atlas"].firstMatch.tap()
        shoot("documents-and-blocks", "note-preview")
        app.button(labeled: "Backlinks").tap()
        shoot("linking", "backlinks-pane")
        dismissSheet()
        app.button(labeled: "Graph").tap()
        shoot("graph", "local-graph")
        if app.buttons["Force"].waitForExistence(timeout: 3) {
            app.buttons["Force"].tap()
            shoot("graph", "graph-force-mode")
        }
        dismissSheet()
        app.button(labeled: "Edit").tap()
        shoot("documents-and-blocks", "note-edit")
        type("\nSee [[Rea", into: app.textViews.firstMatch, atEnd: true)
        shoot("linking", "wikilink-suggestions")
    }

    func testExploreFlow() {
        launchSeeded()
        for (destination, category, name) in [
            ("Tags", "tags", "tag-browser"),
            ("Tasks", "tasks", "task-dashboard"),
            ("Insights", "graph", "graph-insights"),
            ("Saved Views", "search-and-navigation", "saved-views"),
        ] {
            openFromExplore(destination)
            shoot(category, name)
            goBack()
        }
        openFromExplore("Canvas")
        shoot("canvas", "board-list")
        let boards = CanvasBoardListScreen(app: app)
        boards.createBoard(named: "Project Map")
        boards.boardRow(name: "Project Map").tap()
        shoot("canvas", "board-empty")
        if app.button(labeled: "Add Card").waitForExistence(timeout: 5) {
            app.button(labeled: "Add Card").tap()
            shoot("canvas", "add-card-menu")
        }
    }

    func testSearchFlow() {
        launchSeeded()
        openExplore()
        if app.buttons["Command Palette"].waitForExistence(timeout: 3) {
            app.buttons["Command Palette"].tap()
            shoot("search-and-navigation", "command-palette")
            app.button(labeled: "Cancel").tap()
        }
        openTab("Search")
        let field = app.textFields["Search"]
        if field.waitForExistence(timeout: 5) {
            field.tap()
            field.typeText("Atlas")
            shoot("search-and-navigation", "search-results")
        }
        app.button(labeled: "Advanced Search: Off").tap()
        shoot("search-and-navigation", "advanced-search")
    }

    func testSettingsFlow() {
        launchSeeded()
        openTab("Settings")
        shoot("subscription-and-account", "settings-list")
        open("Subscription", shot: ("subscription-and-account", "subscription-settings"))
        open("Sync & Conflicts", shot: ("sync-and-conflicts", "choose-conflict-strategy"))
        open("Backups", shot: ("backup-and-restore", "backups-empty"), keepOpen: true)
        app.button(labeled: "Create Backup").tap()
        shoot("backup-and-restore", "backups-list")
        goBack()
        open("Templates", shot: ("properties-and-templates", "template-groups"))
        open("Template Gallery", shot: ("properties-and-templates", "template-gallery"))
        open("Plugins", shot: ("plugins", "plugin-list"), keepOpen: true)
        app.navigationBars["Plugins (Preview)"].buttons.element(boundBy: 1).tap()
        shoot("plugins", "add-plugin")
        app.button(labeled: "Cancel").tap()
        goBack()
        app.button(labeled: "Sharing").tap()
        shoot("sharing", "share-library")
        dismissSheet(hasDoneButton: true)
        SyncStatusScreen(app: app).open()
        shoot("sync-and-conflicts", "sync-status")
    }

    // MARK: - Helpers

    /// The Explore tab has no accessibility identifier on iPhone, so open it by its label.
    /// Tab bar buttons carry no identifier on iPhone, so open them by label (sidebar rows on Mac/iPad).
    private func openTab(_ name: String) {
#if os(iOS)
        app.buttons[name].tap()
#else
        MainShellScreen(app: app).navigate(to: name)
#endif
    }

    private func openExplore() {
#if os(iOS)
        app.buttons["Explore"].tap()
#endif
    }

    private func openFromExplore(_ destination: String) {
#if os(iOS)
        openExplore()
        app.staticTexts[destination].firstMatch.tap()
#else
        MainShellScreen(app: app).navigate(to: destination)
#endif
    }

    private func launchEmpty() {
        app.launchEnvironment["ResetTemplateOnboarding"] = "1"
        launch()
    }

    private func open(_ row: String, shot: (String, String), keepOpen: Bool = false) {
        app.button(labeled: row).tap()
        shoot(shot.0, shot.1)
        if !keepOpen { goBack() }
    }

    private func goBack() {
#if os(iOS)
        let back = app.navigationBars.buttons.firstMatch
        if back.exists { back.tap() }
#endif
    }

    /// Focuses a text view (a bare `tap()` can miss an empty one) and types.
    private func type(_ text: String, into editor: XCUIElement, atEnd: Bool = false) {
        guard editor.waitForExistence(timeout: 5) else { return }
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: atEnd ? 0.9 : 0.1)).tap()
        _ = app.keyboards.firstMatch.waitForExistence(timeout: 3)
        editor.typeText(text)
    }

    /// Sheets with a toolbar Done button use it; others (Tasks has a "Done" filter chip) are flung down.
    private func dismissSheet(hasDoneButton: Bool = false) {
        if hasDoneButton {
            app.button(labeled: "Done").tap()
        } else {
            // Grab the sheet's top edge and fling it down.
            let grip = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.075))
            grip.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.99)), withVelocity: .fast, thenHoldForDuration: 0)
        }
        sleep(1)
    }

}
#endif
