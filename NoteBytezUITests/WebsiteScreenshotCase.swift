// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  WebsiteScreenshotCase.swift
//  NoteBytezUITests
//

import XCTest

/// Shared base for the website screenshot captures (WebSite20260919v1-WebSite.md Phase W6.5): the
/// `WEBSITE_SCREENSHOTS=1` gate, appearance, seeded launch and attachment naming
/// (`<category>__<name>__<device>-<appearance>`). Settings reach the app as launch *environment*
/// (a Mac `-Key value` launch argument suppresses the window).
class WebsiteScreenshotCase: NoteBytezUITestCase {

    let environment = ProcessInfo.processInfo.environment

    /// Mac flows stop at the first failed step (with a hierarchy dump); iPhone flows keep going.
    var stopsOnFirstFailure: Bool { false }

    override func setUpWithError() throws {
        try XCTSkipUnless(environment["WEBSITE_SCREENSHOTS"] == "1", "Website screenshot capture only")
        try super.setUpWithError()
        continueAfterFailure = !stopsOnFirstFailure
        XCUIDevice.shared.appearance = isDark ? .dark : .light
    }

    var isDark: Bool { environment["WEBSITE_APPEARANCE"] == "dark" }

    var deviceName: String {
#if os(macOS)
        "mac"
#else
        "iphone"
#endif
    }

    func launchSeeded() {
        app.launchEnvironment["SeedScreenshotNotes"] = environment["WEBSITE_SEED_NOTES"] ?? "{}"
        launch()
        sleep(4)
    }

    func shoot(_ category: String, _ name: String) {
#if os(macOS)
        sleep(2) // Mac sheets animate in slowly
#else
        sleep(1)
#endif
#if os(macOS)
        let screenshot = app.windows.firstMatch.screenshot()
#else
        let screenshot = app.screenshot()
#endif
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(category)__\(name)__\(deviceName)-\(isDark ? "dark" : "light")"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

}
