// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase6EntitlementGateTests.swift
//  KontinuumUITests
//
//  NoteBytez20260907v1-Security.md Phase 4 — the entitlement gate's user-facing states, driven
//  by the DEBUG `-SimulateEntitlement <scenario>` launch argument (see `EntitlementSimulation.swift`
//  and `EntitlementGateViewModel.makeDefault()`). DEBUG builds are otherwise never gated, so
//  every other UI test is unaffected.
//

import XCTest

final class Phase6EntitlementGateTests: KontinuumUITestCase {

    private let uiTimeout: TimeInterval = 15

    @MainActor
    private func launch(simulating scenario: String) {
        app.launchArguments += ["-SimulateEntitlement", scenario]
        app.launch()
    }

    // MARK: - Blocked: provenance failed

    @MainActor
    func testProvenanceFailedShowsBlockScreenWithExportAndRestoreButNoResubscribe() throws {
        launch(simulating: "provenanceFailed")

        XCTAssertTrue(app.staticTexts["entitlement.blocked.title"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.buttons["entitlement.exportNotes"].exists)
        XCTAssertTrue(app.buttons["entitlement.restorePurchases"].exists)
        XCTAssertFalse(app.buttons["entitlement.resubscribe"].exists)
    }

    // MARK: - Blocked: subscription lapsed

    @MainActor
    func testLapsedShowsBlockScreenWithResubscribeAndExport() throws {
        launch(simulating: "lapsed")

        XCTAssertTrue(app.staticTexts["entitlement.blocked.title"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.buttons["entitlement.resubscribe"].exists)
        XCTAssertTrue(app.buttons["entitlement.exportNotes"].exists)
        XCTAssertTrue(app.buttons["entitlement.restorePurchases"].exists)
    }

    // MARK: - Blocked: never subscribed → paywall

    @MainActor
    func testNeverSubscribedShowsPaywallWithRestoreAndExport() throws {
        launch(simulating: "neverSubscribed")

        XCTAssertTrue(app.staticTexts["entitlement.paywall.title"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.buttons["entitlement.restorePurchases"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.buttons["entitlement.exportNotes"].exists)
    }

    // MARK: - Warning: banner over a usable app

    @MainActor
    func testWarningShowsLapsedBannerOverUsableApp() throws {
        launch(simulating: "warning")

        // Banner + Resubscribe shown over the real, usable app — S1 is still reachable
        // underneath (the app is not blocked).
        XCTAssertTrue(app.buttons["entitlement.resubscribe"].waitForExistence(timeout: uiTimeout))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "access left")).firstMatch.exists)
        XCTAssertTrue(app.buttons["primaryButton.Create New Library"].exists)
    }

    // MARK: - Full: no gate UI at all

    @MainActor
    func testFullAccessShowsNoEntitlementUI() throws {
        app.launchArguments += ["-SimulateEntitlement", "full"]
        launchAndCreateLibrary(named: "Full Access Library")

        XCTAssertFalse(app.buttons["entitlement.resubscribe"].exists)
        XCTAssertFalse(app.buttons["entitlement.exportNotes"].exists)
        XCTAssertFalse(app.staticTexts["entitlement.paywall.title"].exists)
        XCTAssertFalse(app.staticTexts["entitlement.blocked.title"].exists)
        XCTAssertFalse(app.buttons["primaryButton.Create New Library"].exists)
    }
}
