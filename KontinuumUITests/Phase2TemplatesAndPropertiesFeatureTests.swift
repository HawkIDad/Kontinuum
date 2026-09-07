// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase2TemplatesAndPropertiesFeatureTests.swift
//  KontinuumUITests
//
//  Phase 2 — Feature Coverage: Note Templates (V1) and Properties (V1). Builds a real
//  TemplateGroup → NoteTemplate → Property field through the Template Manager (Settings), then
//  applies that template when creating a document and confirms the field's default value
//  actually pre-fills the Properties block — the full "structured entity" flow Journey 6 relies
//  on, not just that the picker screen renders (already covered by Phase 1).
//
//  Reached via "All Notes", not a Notebook: `TemplatePickerView`'s notebook/journal scopes only
//  show groups explicitly attached via `NotebookTemplateGroup`/`JournalTemplateGroup` — and
//  there is currently no UI anywhere in the app to create that attachment (confirmed absent —
//  neither `NotebookBrowserView`/`NotebookDocumentsView` nor the Template Manager screens
//  reference either join model). "All Notes" documents have no notebook/journal, so
//  `DocumentViewModel.templatePickerScope()` falls back to `.library` — every template,
//  ungrouped — which is the only picker scope this custom template can actually appear in
//  right now. "All Notes" is sidebar-only (regular width); this test runs landscape on an
//  iPhone Pro Max, one of the few iPhone form factors that gets a regular horizontal size class
//  without a full iPad/Mac run.
//
//  Verification status: the Template Manager portion (Settings -> group -> template -> field,
//  through to the field's value actually appearing) is confirmed working end-to-end in this
//  environment. The final "apply via All Notes" leg intermittently fails in this specific
//  landscape-Pro-Max configuration in ways that don't reproduce on iPhone-portrait (this
//  simulator instance also hit the same transient `FBSOpenApplicationServiceErrorDomain`
//  "Busy" launch failures already logged for iPad in Phase 0) — carried forward honestly rather
//  than force-fitted into a false pass; re-verify once a real iPad/Mac run is available.
//

import XCTest

final class Phase2TemplatesAndPropertiesFeatureTests: KontinuumUITestCase {

    @MainActor
    func testCustomNoteTemplateAppliesPropertyDefaultOnCreate() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        launchAndCreateLibrary()
        // The regular-width `NavigationSplitView` sidebar takes a beat longer to finish laying
        // out right after the library-creation transition than `MainShellScreen.navigate`'s own
        // 2s sidebar-existence check allows for. "Today" is the sidebar's first (and initially
        // selected) row, so it's a reliable "the sidebar itself is actually up" signal —
        // "Settings", the last row, needs the same layout pass but isn't worth gambling on being
        // pre-rendered before a scroll.
        XCTAssertTrue(app.sidebarRow("Today").waitForExistence(timeout: 10))
        // Landscape on a phone-height screen is short enough that the sidebar's later rows
        // (Settings is last) may not be laid out until scrolled into view.
        app.collectionViews["Sidebar"].swipeUp()

        // Build "Fiction Writing" > "Character" > Species (default: Kethran) via the Manager.
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).templatesRow.tap()
        let groups = TemplateGroupListScreen(app: app)
        // Deliberately not named "Fiction Writing"/"Character" — `TemplateDAL` ships those
        // exact names as starter seed content (see Decisions Log, NoteBytez-ReleaseFeatures.md),
        // and colliding with the seeded group's own "Character" template (Name/Species/
        // Homeworld/Affiliation/Status) made which one the picker applies ambiguous.
        groups.createGroup(named: "QA Fixture Group")
        let groupRow = groups.groupRow(name: "QA Fixture Group")
        XCTAssertTrue(groupRow.waitForExistence(timeout: 5))
        groupRow.tap()

        let templates = NoteTemplateListScreen(app: app)
        templates.createTemplate(named: "QA Fixture Template")
        let templateRow = templates.templateRow(name: "QA Fixture Template")
        XCTAssertTrue(templateRow.waitForExistence(timeout: 5))
        templateRow.tap()

        let fields = NoteTemplateFieldsScreen(app: app)
        fields.addField(named: "Species", defaultValue: "Kethran")
        XCTAssertTrue(app.element(labeledContaining: "Species").waitForExistence(timeout: 5))

        // Scroll back to the top — the earlier scroll to reach "Settings" left "All Notes"
        // (near the top of the same list) out of view.
        app.collectionViews["Sidebar"].swipeDown()
        let allNotesRow = app.sidebarRow("All Notes")
        try XCTSkipUnless(allNotesRow.waitForExistence(timeout: 5), "Needs a regular horizontal size class — All Notes is sidebar-only.")
        allNotesRow.tap()

        let allNotes = DocumentListScreen(app: app)
        XCTAssertTrue(allNotes.navigationTitle.waitForExistence(timeout: 5))
        allNotes.newNoteButton.tap()

        let picker = TemplatePickerScreen(app: app)
        XCTAssertTrue(picker.navigationTitle.waitForExistence(timeout: 5))
        // The sheet's title animates in before its `List` has necessarily finished laying out
        // rows — "Start Blank" is always present (`showsStartBlankOption` defaults `true`), so
        // waiting for it first is a reliable "the list itself is actually populated" signal.
        XCTAssertTrue(picker.startBlankButton.waitForExistence(timeout: 5), String(app.debugDescription.prefix(3000)))
        let characterOption = app.button(labeled: "QA Fixture Template")
        XCTAssertTrue(characterOption.waitForExistence(timeout: 5), String(app.debugDescription.prefix(3000)))
        characterOption.tap()

        let untitledRow = app.button(labeled: "Untitled")
        XCTAssertTrue(untitledRow.waitForExistence(timeout: 5))
        untitledRow.tap()

        // S17 — the template's Property, pre-filled with its default value, without ever
        // entering edit mode: this is what proves the template actually applied, not just that
        // the picker was shown.
        let document = DocumentScreen(app: app)
        XCTAssertTrue(document.titleField.waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(labeled: "Species").waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["Value"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["Value"].value as? String, "Kethran")
    }

}
