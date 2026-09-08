// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SimulatedEntitlementProviderTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

#if DEBUG

/// The DEBUG `-SimulateEntitlement` seam that `Phase6EntitlementGateTests` and manual QA rely
/// on. The live `StoreKitEntitlementProvider` is exercised via `SKTestSession` in Xcode with the
/// `Kontinuum.storekit` configuration attached to the test plan (Phase 0 / Phase 8); here we
/// only lock down the fake's scenario → snapshot mapping.
struct SimulatedEntitlementProviderTests {

    @Test func launchArgumentParsingRejectsUnknownValues() {
        let defaults = UserDefaults(suiteName: "SimEntitlement-\(UUID().uuidString)")!
        defaults.set("banana", forKey: "SimulateEntitlement")
        #expect(SimulatedEntitlementProvider.fromLaunchArguments(defaults) == nil)
    }

    @Test func launchArgumentParsingAcceptsKnownScenarios() {
        let defaults = UserDefaults(suiteName: "SimEntitlement-\(UUID().uuidString)")!
        defaults.set("lapsed", forKey: "SimulateEntitlement")
        #expect(SimulatedEntitlementProvider.fromLaunchArguments(defaults)?.scenario == .lapsed)
    }

    @Test func provenanceFailedYieldsNoEnvironment() async {
        let provider = SimulatedEntitlementProvider(scenario: .provenanceFailed)
        #expect(await provider.verifyProvenance() == nil)
    }

    @Test func nonFailureScenariosAreProduction() async {
        for scenario in [SimulatedEntitlementProvider.Scenario.full, .warning, .trial, .lapsed, .neverSubscribed] {
            let provider = SimulatedEntitlementProvider(scenario: scenario)
            #expect(await provider.verifyProvenance() == .production)
        }
    }

    @Test func fullScenarioReportsAnActiveSubscription() async {
        let provider = SimulatedEntitlementProvider(scenario: .full)
        let snapshot = await provider.currentSubscription()
        #expect(snapshot?.isActive(asOf: Date()) == true)
    }

    @Test func warningScenarioReportsARecentlyExpiredSubscription() async {
        let provider = SimulatedEntitlementProvider(scenario: .warning)
        let snapshot = await provider.currentSubscription()
        #expect(snapshot != nil)
        #expect(snapshot?.isActive(asOf: Date()) == false)
    }

    @Test func neverSubscribedScenarioReportsNoSubscription() async {
        let provider = SimulatedEntitlementProvider(scenario: .neverSubscribed)
        #expect(await provider.currentSubscription() == nil)
    }
}

#endif
