// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  WebsiteScreenshotMacTests.swift
//  NoteBytezUITests
//

import XCTest

#if os(macOS)
/// Mac flows for the website screenshots (see `WebsiteScreenshotCase`). Driven through what the Mac
/// app exposes natively — sidebar rows, menu-bar commands and keyboard shortcuts — instead of
/// hunting toolbar buttons that can sit in the overflow menu. Each step asserts its target and the
/// flow stops at the first failure with a hierarchy dump attached, so one run shows what to fix.
final class WebsiteScreenshotMacTests: WebsiteScreenshotCase {

    override var stopsOnFirstFailure: Bool { true }

    // MARK: - Flows

    func testSidebarScreens() throws {
        try launchAndActivate()
        for (destination, category, name) in [
            ("Today", "capture-and-journal", "todays-journal"),
            ("Notebooks", "notebooks", "notebook-browser"),
            ("Tags", "tags", "tag-browser"),
            ("Tasks", "tasks", "task-dashboard"),
            ("Insights", "graph", "graph-insights"),
            ("Saved Views", "search-and-navigation", "saved-views"),
            ("Canvas", "canvas", "board-list"),
            ("Settings", "subscription-and-account", "settings-list"),
        ] {
            try openSidebar(destination)
            shoot(category, name)
        }
    }

    func testNotesAndLinkingFlow() throws {
        try launchAndActivate()
        try openSidebar("Notebooks")
        try click(toolbar: "New Notebook")
        shoot("notebooks", "new-notebook-sheet")
        closeSheet()
        try click(text: "Projects")
        shoot("notebooks", "notebook-documents")
        try click(toolbar: "New Note")
        shoot("documents-and-blocks", "template-picker")
        closeSheet()
        try click(text: "Project Atlas")
        shoot("documents-and-blocks", "note-preview")
        try click(button: "Backlinks")
        shoot("linking", "backlinks-pane")
        closeSheet()
        try click(button: "Graph")
        _ = try require(app.button(labeled: "Zoom In"), "graph zoom controls")
        shoot("graph", "local-graph")
        // graph-force-mode is iPhone-only: the Mac graph sheet does not expose its Radial/Force picker to XCUITest.
        closeSheet()
        try click(button: "Edit")
        shoot("documents-and-blocks", "note-edit")
        try type("\nSee [[Rea", intoEditorAtEnd: true)
        shoot("linking", "wikilink-suggestions")
    }

    func testJournalAndPromoteFlow() throws {
        try launchAndActivate()
        let editor = try require(app.textViews.firstMatch, "journal editor")
        editor.click()
        editor.typeText("A new idea worth its own note")
        try click(toolbar: "Quick Switcher")
        shoot("search-and-navigation", "quick-switcher")
        closeSheet()
        try click(toolbar: "Tasks")
        shoot("tasks", "tasks-sheet")
        closeSheet()
        // Excluded on Mac: the Promote a Block sheet lays its block list out at zero size (rows exist but
        // are not hittable and the sheet shows only Cancel), so notebooks/promote-* are iPhone-only.
    }

    func testExploreFlow() throws {
        try launchAndActivate()
        try openSidebar("Canvas")
        try click(toolbar: "New Board")
        shoot("canvas", "new-board-sheet")
        let name = try require(app.textFields["Board Name"], "board name field")
        name.click()
        name.typeText("Project Map")
        try click(button: "Create")
        try click(text: "Project Map")
        shoot("canvas", "board-empty")
        // The Add Card menu is the "+" at the top right of the board toolbar (not exposed by label).
        app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.875, dy: 0.037)).click()
        shoot("canvas", "add-card-menu")
        closeSheet()
    }

    func testSearchFlow() throws {
        try launchAndActivate()
        app.typeKey("p", modifierFlags: .command)
        shoot("search-and-navigation", "command-palette")
        closeSheet()
        try openSidebar("Search")
        let field = try require(app.textFields["Search"], "search field")
        field.click()
        field.typeText("Atlas")
        shoot("search-and-navigation", "search-results")
        try click(button: "Advanced Search: Off")
        shoot("search-and-navigation", "advanced-search")
    }

    func testSettingsFlow() throws {
        try launchAndActivate()
        try openSidebar("Settings")
        for (row, category, name) in [
            ("Subscription", "subscription-and-account", "subscription-settings"),
            ("Sync & Conflicts", "sync-and-conflicts", "choose-conflict-strategy"),
            ("Backups", "backup-and-restore", "backups-empty"),
            ("Templates", "properties-and-templates", "template-groups"),
            ("Template Gallery", "properties-and-templates", "template-gallery"),
            ("Plugins", "plugins", "plugin-list"),
        ] {
            try click(text: row)
            shoot(category, name)
            if row == "Backups" {
                try click(button: "Create Backup")
                shoot("backup-and-restore", "backups-list")
            }
            if row == "Plugins" {
                try click(toolbar: "Add")
                shoot("plugins", "add-plugin")
                closeSheet()
            }
            try click(button: "Back")
        }
        try click(text: "Sharing")
        shoot("sharing", "share-library")
        closeSheet()
        // sync-and-conflicts/sync-status is iPhone-only: the Mac toolbar does not expose the sync glyph.
    }

    func testGettingStartedFlow() throws {
        app.launchEnvironment["ResetTemplateOnboarding"] = "1"
        launch()
        app.activate()
        _ = try require(app.buttons["primaryButton.Create New Library"], "Create New Library")
        shoot("getting-started", "library-picker")
        app.buttons["primaryButton.Create New Library"].click()
        let name = try require(app.textFields["newLibrary.nameField"], "library name field")
        shoot("getting-started", "create-library-sheet")
        name.click()
        name.typeText("My Library")
        try require(app.buttons["primaryButton.Create"], "Create").click()
        _ = try require(app.staticTexts["What do you use NoteBytez for?"], "role picker", timeout: 10)
        shoot("getting-started", "role-picker")
    }

    /// Plugin commands end to end (NoteBytez20260924v1-PluginCommands.md): with three seeded plugins,
    /// see the registration failure, run one command from the palette and see the note change, then
    /// see the run-time failure alert.
    func testPluginCommandFlow() throws {
        launchSeeded(withPlugins: true)
        app.activate()
        _ = try require(app.sidebarRow("Today"), "sidebar row Today")
        try openSidebar("Settings")
        try click(text: "Plugins")
        _ = try require(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "no commands for you", "no commands for you")).firstMatch, "registration failure caption")
        shoot("plugins", "plugin-registration-error")

        try openSidebar("Today")
        let editor = try require(app.textViews.firstMatch, "journal editor")
        try runPaletteCommand("Say Hello", screenshot: "palette-plugin-command")
        let hasAppended = NSPredicate(format: "value CONTAINS %@", "Hello from a plugin")
        wait(for: [expectation(for: hasAppended, evaluatedWith: editor)], timeout: 8)

        try runPaletteCommand("Explode", screenshot: nil)
        _ = try require(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@", "boom", "boom")).firstMatch, "alert text names the error")
        shoot("plugins", "plugin-run-error")
        try require(app.sheets.buttons["OK"], "alert OK").click() // scoped: the Touch Bar also has an OK
    }

    // MARK: - Helpers

    private func launchAndActivate() throws {
        launchSeeded()
        app.activate()
        _ = try require(app.sidebarRow("Today"), "sidebar row Today")
    }

    private func openSidebar(_ destination: String) throws {
        let row = try require(app.sidebarRow(destination), "sidebar row \(destination)")
        row.click()
        sleep(1)
    }

    /// Fails the test and throws (stopping the flow) with the accessibility hierarchy attached.
    @discardableResult
    private func require(_ element: XCUIElement, _ what: String, timeout: TimeInterval = 8) throws -> XCUIElement {
        guard element.waitForExistence(timeout: timeout) else {
            let dump = XCTAttachment(string: app.debugDescription)
            dump.name = "hierarchy at failure: \(what)"
            dump.lifetime = .keepAlways
            add(dump)
            XCTFail("Not found: \(what)")
            throw MacFlowError.missing(what)
        }
        return element
    }

    private func click(button label: String) throws {
        try require(app.button(labeled: label), "button \(label)").click()
        sleep(1)
    }

    /// A list row: on the Mac a NavigationLink row is a button labelled "<title>, <detail>", not static text.
    private func click(text: String) throws {
        let scope = app.sheets.firstMatch.exists ? app.sheets.firstMatch.buttons : app.buttons
        let starting = scope.matching(NSPredicate(format: "label BEGINSWITH %@", text)).firstMatch
        let containing = scope.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        let target = starting.waitForExistence(timeout: 4) ? starting : (containing.waitForExistence(timeout: 2) ? containing : app.staticTexts[text].firstMatch)
        try require(target, "row \(text)").click()
        sleep(1)
    }

    /// A toolbar item by label; when the toolbar collapses it into the overflow menu, opens that first.
    private func click(toolbar label: String) throws {
        let direct = app.button(labeled: label)
        let anyElement = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", label)).firstMatch
        if direct.waitForExistence(timeout: 3) {
            direct.click()
        } else if anyElement.exists {
            anyElement.click()
        } else {
            let overflow = try require(app.popUpButtons["more toolbar items"], "toolbar overflow")
            overflow.click()
            try require(app.menuItems[label], "overflow item \(label)").click()
        }
        sleep(1)
    }

    private func type(_ text: String, intoEditorAtEnd: Bool) throws {
        let editor = try require(app.textViews.firstMatch, "note editor")
        editor.click()
        app.typeKey(.downArrow, modifierFlags: .command)
        editor.typeText(text)
    }

    private func waitUntilHittable(_ element: XCUIElement, timeout: TimeInterval = 10) throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !element.isHittable {
            guard Date() < deadline else { XCTFail("Never became hittable: \(element)"); throw MacFlowError.missing("hittable \(element)") }
            usleep(300_000)
        }
    }

    /// ⌘P, filter to `title`, optionally capture the palette, then Return to run the top hit.
    private func runPaletteCommand(_ title: String, screenshot: String?) throws {
        app.typeKey("p", modifierFlags: .command)
        let field = try require(app.textFields["Type a command or search…"], "palette field")
        field.click()
        field.typeText(title)
        _ = try require(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", title)).firstMatch, "palette row \(title)")
        if let screenshot { shoot("plugins", screenshot) }
        app.typeKey(.return, modifierFlags: [])
        sleep(2)
    }

    private func closeSheet() {
        app.typeKey(.escape, modifierFlags: [])
        sleep(1)
    }

    private enum MacFlowError: Error { case missing(String) }

}
#endif
