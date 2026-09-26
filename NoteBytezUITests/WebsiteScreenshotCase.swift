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

    /// The plugins the plugin-command flow needs, installed with `SeedScreenshotPlugins` (typing a
    /// script into the install sheet is unreliable: smart quotes, keyboard-covered toggles).
    /// `Hello` appends to the note; `Explode` fails when run; `Broken` fails to register.
    static let seededPluginsJSON: String = {
        let plugins: [[String: Any]] = [
            ["name": "Hello", "permissions": ["addCommand", "writeCurrentNote"],
             "script": "if (noteBytez.invokedCommand === null) { noteBytez.addCommand(\"Say Hello\"); } else { noteBytez.appendToCurrentNote(\"Hello from a plugin\"); }"],
            ["name": "Explode", "permissions": ["addCommand"],
             "script": "if (noteBytez.invokedCommand === null) { noteBytez.addCommand(\"Explode\"); } else { throw new Error(\"boom\"); }"],
            ["name": "Broken", "permissions": ["addCommand"],
             "script": "throw new Error(\"no commands for you\");"],
        ]
        return (try? JSONSerialization.data(withJSONObject: plugins)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }()

    func launchSeeded(withPlugins: Bool = false) {
        app.launchEnvironment["SeedScreenshotNotes"] = environment["WEBSITE_SEED_NOTES"] ?? "{}"
        if withPlugins { app.launchEnvironment["SeedScreenshotPlugins"] = Self.seededPluginsJSON }
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
