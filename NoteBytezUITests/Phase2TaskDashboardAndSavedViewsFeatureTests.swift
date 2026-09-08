// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase2TaskDashboardAndSavedViewsFeatureTests.swift
//  NoteBytezUITests
//
//  Phase 2 — Feature Coverage: Task Dashboards (V1) and Saved Views (V1). Writes a real task via
//  the journal, confirms it's cross-note-listed on the Task Dashboard, then saves both a search
//  and a task filter and confirms each reappears as a `SavedViewChip` (Search/Tasks fold Saved
//  Views inline on iPhone rather than a dedicated S21 tab — see `05-Wireframes.md`) and is
//  re-runnable — not just that the dashboard/save-alert screens render (already covered by
//  Phase 1).
//

import XCTest

final class Phase2TaskDashboardAndSavedViewsFeatureTests: NoteBytezUITestCase {

    @MainActor
    func testJournalTaskAppearsOnDashboardAndFilterIsSavable() throws {
        launchAndCreateLibrary()
        let today = TodayJournalScreen(app: app)
        today.writeAndPersist("\n- [ ] Review the PR from Dana #standup")

        XCTAssertTrue(today.tasksButton.waitForExistence(timeout: 5))
        today.tasksButton.tap()

        let tasks = TaskDashboardScreen(app: app)
        XCTAssertTrue(tasks.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(tasks.taskRow(containing: "Review the PR from Dana").waitForExistence(timeout: 5))

        // Save the current (default: Open) filter set as a Saved View. The alert's field is
        // pre-filled with a default name ("Open Tasks") — select-all first, or typing appends
        // instead of replacing it.
        tasks.saveFiltersButton.tap()
        XCTAssertTrue(tasks.saveTaskViewNameField.waitForExistence(timeout: 5))
        tasks.saveTaskViewNameField.tap()
        tasks.saveTaskViewNameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 40))
        tasks.saveTaskViewNameField.typeText("Open Standup Tasks")
        tasks.saveTaskViewConfirmButton.tap()

        let taskChip = tasks.savedViewChip(name: "Open Standup Tasks")
        XCTAssertTrue(taskChip.waitForExistence(timeout: 5))
        taskChip.tap()
        // Re-running it (a fresh navigation push each time — never a frozen snapshot) lands on
        // its own results screen, still showing the same task.
        XCTAssertTrue(app.navigationBars["Open Standup Tasks"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(labeledContaining: "Review the PR from Dana").waitForExistence(timeout: 5))
    }

    @MainActor
    func testSavedSearchReappearsAsChipAndReruns() throws {
        launchAndCreateLibrary()
        let today = TodayJournalScreen(app: app)
        // Trailing space closes the `#roadmap` tag's autocomplete query — without it, the
        // suggestion-chip row stays open over the bottom of the screen and intercepts the tab
        // bar tap that follows.
        //
        // Known intermittent: switching tabs immediately after `writeAndPersist`'s day-navigation
        // round trip is unreliable specifically under XCUITest's synthesized-event timing — a
        // manual, human-paced repro of the identical steps (type -> Previous -> Next -> tap
        // Search) in the Simulator switches tabs on the first tap every time, so this isn't a
        // product bug, but the exact automated-timing cause wasn't pinned down before deciding
        // the ROI on further digging wasn't worth it. `sleep(3)` is a real mitigation (confirmed
        // it does change the failure signature versus no wait at all) but not a proven-reliable
        // fix; if this test flakes, that's why.
        today.writeAndPersist("\n- Roadmap planning notes #roadmap ")

        sleep(3)
        let shell = MainShellScreen(app: app)
        shell.navigate(to: "Search")
        let search = SearchScreen(app: app)
        XCTAssertTrue(search.navigationTitle.waitForExistence(timeout: 5), String(app.debugDescription.prefix(3000)))
        search.searchField.tap()
        search.searchField.typeText("roadmap")
        XCTAssertTrue(app.element(labeledContaining: "Roadmap planning notes").waitForExistence(timeout: 5), String(app.debugDescription.prefix(3000)))

        // Pre-filled with the query text ("roadmap") — select-all first, same as the task
        // filter's save alert.
        search.saveSearchButton.tap()
        XCTAssertTrue(search.saveSearchNameField.waitForExistence(timeout: 5))
        search.saveSearchNameField.tap()
        search.saveSearchNameField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 40))
        search.saveSearchNameField.typeText("Roadmap Notes")
        search.saveSearchConfirmButton.tap()

        let chip = search.savedViewChip(name: "Roadmap Notes")
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        chip.tap()
        XCTAssertTrue(app.navigationBars["Roadmap Notes"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.element(labeledContaining: "Roadmap planning notes").waitForExistence(timeout: 5))
    }

}
