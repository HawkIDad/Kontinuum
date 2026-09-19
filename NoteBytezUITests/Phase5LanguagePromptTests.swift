// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase5LanguagePromptTests.swift
//  NoteBytezUITests
//
//  NoteBytez20260823v2-MultiLanguage.md Phase 5.8 — the first-launch language prompt (5.4) and
//  the Settings language override (5.5). `SupportedLocales` ships only `en-US` today (5.3 —
//  Phases 6-11 add the rest), so "select a different, already-shipped language and confirm it
//  renders" genuinely can't be tested yet without offering a locale with zero real UI
//  translations, which is exactly what G4b says never to do. What's tested instead: the
//  mechanism itself — the prompt gates entry into the rest of the app, is shown exactly once,
//  and a Settings change persists across a real restart — using the one locale that actually
//  exists. Revisit once a second locale ships (Phase 7) to add the "renders in a different
//  language" assertion the plan's own 5.8(b) wording anticipates.
//

import XCTest

final class Phase5LanguagePromptTests: NoteBytezUITestCase {

    // MARK: - 5.8(a) — precedes the entitlement gate, shown exactly once

    @MainActor
    func testFirstLaunchPromptPrecedesTheEntitlementGateAndIsNotShownAgainAfterConfirming() throws {
        // Deliberately bypasses `launch()`'s `-SkipLanguagePrompt` default — this test is
        // specifically about the un-skipped first-launch path. `-ResetLanguagePreference` forces
        // a clean slate regardless of what an earlier run of this same test (or a manual session)
        // already left in this simulator's persisted `UserDefaults`. Paired with
        // `-SimulateEntitlement neverSubscribed` so "before the entitlement gate ever renders"
        // is a concrete, checkable claim (DEBUG builds are otherwise never gated at all — see
        // `EntitlementGateViewModel.makeDefault()` — so there'd be no gate UI to check against).
        app.launchArguments += ["-ResetLanguagePreference", "-SimulateEntitlement", "neverSubscribed"]
        app.launch()

        let prompt = LanguagePromptScreen(app: app)
        let englishOption = prompt.option(forLocaleId: "en-US")
        XCTAssertTrue(englishOption.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["entitlement.paywall.title"].exists,
                        "the entitlement gate must not render until the language prompt is confirmed")

        prompt.confirm()

        XCTAssertTrue(app.staticTexts["entitlement.paywall.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(englishOption.exists, "the prompt must not still be present once confirmed")

        // Relaunching the same (already-confirmed) app must land straight on the paywall again —
        // `hasPromptedForLanguage` persists to `UserDefaults.standard`, which (unlike the
        // in-memory SwiftData store) survives across launches on the same simulator.
        // `launchArguments` itself persists across `.launch()` calls on the same `XCUIApplication`
        // instance, so `-ResetLanguagePreference` must be dropped here — otherwise this second
        // launch would wipe `hasPromptedForLanguage` right back to `false` and defeat the very
        // thing this assertion is checking.
        app.terminate()
        app.launchArguments = ["-SimulateEntitlement", "neverSubscribed"]
        app.launch()

        XCTAssertTrue(app.staticTexts["entitlement.paywall.title"].waitForExistence(timeout: 5))
        XCTAssertFalse(prompt.option(forLocaleId: "en-US").exists, "the prompt must not reappear on a later launch")
    }

    // MARK: - 5.8(b) — Settings override persists across a restart

    @MainActor
    func testSettingsLanguageOverridePersistsAcrossARestart() throws {
        launchAndCreateLibrary()

        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).languageRow.tap()

        let languageSettings = LanguageSettingsScreen(app: app)
        XCTAssertTrue(languageSettings.navigationTitle.waitForExistence(timeout: 5))
        XCTAssertTrue(languageSettings.systemDefaultRow.waitForExistence(timeout: 5), "System Default must be offered even with only one shipped locale")

        // `LocalePreferenceStore` persists to `UserDefaults.standard`, which survives across
        // launches (and other tests) on the same simulator — force a known baseline rather than
        // assuming "System Default" is what's currently selected, mirroring
        // `Phase1ConflictResolutionSmokeTests`'s own handling of the same persistence quirk.
        languageSettings.systemDefaultRow.tap()
        XCTAssertTrue(languageSettings.systemDefaultRow.isSelected)

        let englishRow = languageSettings.row(forLocaleId: "en-US")
        XCTAssertTrue(englishRow.waitForExistence(timeout: 5))
        XCTAssertFalse(englishRow.isSelected, "System Default was just selected above")
        englishRow.tap()
        XCTAssertTrue(englishRow.isSelected)

        // Restart — the documented "changes take effect after restart" caveat (G4a). Since
        // `en-US` is also the source/development language, this can't show a *visibly* different
        // UI language yet; what it proves is that the explicit choice actually persisted through
        // a real process restart (reflected back as the checked row), not just in in-memory
        // `@State` that a fresh `LanguageSettingsView` would otherwise re-initialize to
        // System Default.
        app.terminate()
        app.launch()

        // The Debug build's SwiftData store is in-memory only (`NoteBytezApp.swift`), so the
        // library created above didn't survive the restart either — `LocalePreferenceStore`'s
        // `UserDefaults`-backed preference is the only thing this test expects to persist.
        LibrarySelectionScreen(app: app).createLibrary(named: "UI Test Library 2")
        MainShellScreen(app: app).navigate(to: "Settings")
        SettingsScreen(app: app).languageRow.tap()
        let englishRowAfterRestart = LanguageSettingsScreen(app: app).row(forLocaleId: "en-US")
        XCTAssertTrue(englishRowAfterRestart.waitForExistence(timeout: 5))
        XCTAssertTrue(englishRowAfterRestart.isSelected, "the explicit choice must survive a real process restart")
    }

}
