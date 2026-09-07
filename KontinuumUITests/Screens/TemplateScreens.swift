// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateScreens.swift
//  KontinuumUITests
//

import XCTest

/// S18 — Template Picker (the higher-frequency sub-flow), reached from "+ New Note" wherever a
/// document can be created (Notebook, All Notes).
struct TemplatePickerScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Choose a Template"] }
    var startBlankButton: XCUIElement { app.button(labeled: "Start Blank (no template)") }
    var cancelButton: XCUIElement { app.button(labeled: "Cancel") }

}

/// S18 Manager sub-flow — reached from Settings → "Templates".
struct TemplateGroupListScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Templates"] }
    var groupNameField: XCUIElement { app.textFields["Group name"] }
    var addGroupButton: XCUIElement { app.button(labeled: "Add") }

    @discardableResult
    func createGroup(named name: String) -> Self {
        XCTAssertTrue(groupNameField.waitForExistence(timeout: 5))
        groupNameField.tap()
        groupNameField.typeText(name)
        addGroupButton.tap()
        app.dismissKeyboard()
        return self
    }

    func groupRow(name: String) -> XCUIElement { app.button(labeled: name) }

}

/// S18 Manager, level 2 — templates within one group.
struct NoteTemplateListScreen {

    let app: XCUIApplication

    var templateNameField: XCUIElement { app.textFields["Template name"] }
    var addTemplateButton: XCUIElement { app.button(labeled: "Add") }

    func templateRow(name: String) -> XCUIElement { app.button(labeled: name) }

    @discardableResult
    func createTemplate(named name: String) -> Self {
        XCTAssertTrue(templateNameField.waitForExistence(timeout: 5))
        templateNameField.tap()
        templateNameField.typeText(name)
        addTemplateButton.tap()
        app.dismissKeyboard()
        return self
    }

}

/// S18 Manager, level 3 — one template's pre-filled Property fields.
struct NoteTemplateFieldsScreen {

    let app: XCUIApplication

    var fieldNameField: XCUIElement { app.textFields["Field name"] }
    var defaultValueField: XCUIElement { app.textFields["Default value (optional)"] }
    var addFieldButton: XCUIElement { app.button(labeled: "Add Field") }

    @discardableResult
    func addField(named name: String, defaultValue: String) -> Self {
        XCTAssertTrue(fieldNameField.waitForExistence(timeout: 5))
        fieldNameField.tap()
        fieldNameField.typeText(name)
        defaultValueField.tap()
        defaultValueField.typeText(defaultValue)
        addFieldButton.tap()
        app.dismissKeyboard()
        return self
    }

}
