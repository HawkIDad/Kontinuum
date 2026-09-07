// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SubscriptionSettingsViewModel.swift
//  Kontinuum
//

import Foundation
import Observation

/// Read-only status for the Settings → Subscription screen (NoteBytez20260907v1-Security.md
/// Phase 6). Purely descriptive — it never suspends sync or changes the gate; that stays with
/// `EntitlementGateViewModel`.
@MainActor
@Observable
final class SubscriptionSettingsViewModel {

    private(set) var statusLine = "Checking…"
    private(set) var detailLine: String?

    private let provider: EntitlementProviding
    private let now: () -> Date

    init(provider: EntitlementProviding = StoreKitEntitlementProvider(), now: @escaping () -> Date = { Date() }) {
        self.provider = provider
        self.now = now
    }

    func load() async {
        guard let environment = await provider.verifyProvenance() else {
            statusLine = "Not verified"
            detailLine = "This copy couldn’t be verified with the App Store."
            return
        }

        if environment.isSubscriptionWaived {
            statusLine = "TestFlight / development build"
            detailLine = "A subscription isn’t required for this build."
            return
        }

        guard let subscription = await provider.currentSubscription() else {
            statusLine = "No active subscription"
            detailLine = nil
            return
        }

        let plan = subscription.productId == Entitlement.Products.annual ? "Annual" : "Monthly"
        let familyNote = subscription.isFamilyShared ? " · shared with you via Family Sharing" : ""
        statusLine = "\(plan) subscription\(familyNote)"

        if let expiry = subscription.expirationDate {
            let verb = subscription.isActive(asOf: now()) ? "Renews" : "Expired"
            detailLine = "\(verb) \(expiry.formatted(date: .abbreviated, time: .omitted))"
        } else {
            detailLine = nil
        }
    }
}
