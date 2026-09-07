// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportScreens.swift
//  KontinuumUITests
//

import XCTest

/// S2 — Import Scan & Confirm. Reached only after the system folder picker (triggered by
/// `LibrarySelectionScreen.importFolderButton`) resolves a folder — driving that picker
/// reliably from XCUITest is a known simulator/system-UI automation gap (see
/// Docs/Plans/NoteBytez20260823v1-UITests.md), so this page object covers the screen that
/// *would* render once a folder is chosen; the picker itself isn't driven here.
struct ImportScanScreen {

    let app: XCUIApplication

    var navigationTitle: XCUIElement { app.navigationBars["Import Preview"] }
    var cancelButton: XCUIElement { app.button(labeled: "Cancel") }
    var confirmImportButton: XCUIElement { app.button(labeled: "Confirm Import") }

}
