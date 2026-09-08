// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskScreen.swift
//  NoteBytezUITests
//

import XCTest

/// S19 — Task Dashboard. Reached via `TodayJournalScreen.tasksButton` (sheet) or the "Tasks"
/// sidebar item on Mac/iPad.
struct TaskDashboardScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Tasks"] }
    var tagFilterField: XCUIElement { app.textFields["Filter by tag"] }
    var saveFiltersButton: XCUIElement { app.button(labeled: "Save These Filters") }

    func statusFilterChip(_ title: String) -> XCUIElement { app.button(labeled: title) }

    func taskRow(containing text: String) -> XCUIElement { app.element(labeledContaining: text) }

    // "Save Task View" alert
    var saveTaskViewNameField: XCUIElement { app.textFields["Name"] }
    var saveTaskViewConfirmButton: XCUIElement { app.alerts.buttons["Save"] }

    func savedViewChip(name: String) -> XCUIElement { app.element(labeledContaining: name) }

}
