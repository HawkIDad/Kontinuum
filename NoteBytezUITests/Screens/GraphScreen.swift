// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphScreen.swift
//  KontinuumUITests
//

import XCTest

/// S8 — Local Graph View.
struct GraphScreen {

    let app: XCUIApplication

    var zoomInButton: XCUIElement { app.button(labeled: "Zoom In") }
    var zoomOutButton: XCUIElement { app.button(labeled: "Zoom Out") }
    var fitToScreenButton: XCUIElement { app.button(labeled: "Fit to Screen") }

}
