// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  EntitlementSimulation.swift
//  Kontinuum
//

#if DEBUG
import Foundation

/// DEBUG-only canned `EntitlementProviding` driven by a `-SimulateEntitlement <scenario>` launch
/// argument, mirroring `NoteBytezApp`'s existing `-SeedTestConflict` / `-EnableLiveSync` seams.
/// Lets `Phase6EntitlementGateTests` and manual QA reach every gate state without a live
/// StoreKit environment. Never compiled into a Release build.
struct SimulatedEntitlementProvider: EntitlementProviding {

    enum Scenario: String {
        case full
        case warning
        case trial
        case lapsed
        case provenanceFailed
        case neverSubscribed
    }

    let scenario: Scenario

    static func fromLaunchArguments(_ defaults: UserDefaults = .standard) -> SimulatedEntitlementProvider? {
        guard let raw = defaults.string(forKey: "SimulateEntitlement"),
              let scenario = Scenario(rawValue: raw) else { return nil }
        return SimulatedEntitlementProvider(scenario: scenario)
    }

    func verifyProvenance() async -> EntitlementEnvironment? {
        scenario == .provenanceFailed ? nil : .production
    }

    func currentSubscription() async -> SubscriptionSnapshot? {
        let day: TimeInterval = 24 * 60 * 60
        switch scenario {
        case .full, .trial:
            return snapshot(expiringIn: 30 * day)
        case .warning:
            return snapshot(expiringIn: -1 * day)
        case .lapsed:
            return snapshot(expiringIn: -10 * day)
        case .provenanceFailed, .neverSubscribed:
            return nil
        }
    }

    var transactionUpdates: AsyncStream<Void> {
        AsyncStream { $0.finish() }
    }

    private func snapshot(expiringIn offset: TimeInterval) -> SubscriptionSnapshot {
        SubscriptionSnapshot(
            productId: Entitlement.Products.monthly,
            expirationDate: Date().addingTimeInterval(offset),
            isFamilyShared: false,
            isInAppleGracePeriod: false,
            revocationDate: nil
        )
    }
}
#endif
