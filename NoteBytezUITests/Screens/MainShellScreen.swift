// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MainShellScreen.swift
//  NoteBytezUITests
//

import XCTest

/// Page-object for the app's main navigation shell (`ContentView`) — a sectioned sidebar on
/// Mac/expanded iPad, a 5-tab bar on iPhone/compact iPad (Today, Notebooks, Search, Explore,
/// Settings) on iPhone/compact iPad. Looks for either identifier so journey tests don't need to
/// branch on platform themselves; a destination with no tab of its own (Graph, Insights, Tasks,
/// Saved Views, Canvas, Tags) is reached through the Explore hub tab instead.
struct MainShellScreen {

    let app: XCUIApplication

    private static let tabBarDestinations: Set<String> = ["Today", "Notebooks", "Search", "Explore", "Settings"]

    func navigate(to destination: String) {
        let sidebarRow = app.sidebarRow(destination)
        if sidebarRow.waitForExistence(timeout: 2) {
            sidebarRow.tap()
            return
        }
        if Self.tabBarDestinations.contains(destination) {
            tabBarButton(destination).tap()
            return
        }
        tabBarButton("Explore").tap()
        app.staticTexts[destination].firstMatch.tap()
    }

    private func tabBarButton(_ destination: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", "tabbar.\(destination)")).firstMatch
    }

}
