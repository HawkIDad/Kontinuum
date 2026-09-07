// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SubscriptionSettingsViewModelTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

/// Settings → Subscription status strings across the entitlement states (Phase 6). Reuses
/// `FakeEntitlementProvider` from `EntitlementGateViewModelTests`.
@MainActor
struct SubscriptionSettingsViewModelTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    private func load(_ provider: FakeEntitlementProvider) async -> SubscriptionSettingsViewModel {
        let viewModel = SubscriptionSettingsViewModel(provider: provider, now: { self.now })
        await viewModel.load()
        return viewModel
    }

    private func snapshot(productId: String, endsAfter offset: TimeInterval, isFamilyShared: Bool = false) -> SubscriptionSnapshot {
        SubscriptionSnapshot(
            productId: productId,
            expirationDate: now.addingTimeInterval(offset),
            isFamilyShared: isFamilyShared,
            isInAppleGracePeriod: false,
            revocationDate: nil
        )
    }

    @Test func unverifiedProvenanceReportsNotVerified() async {
        let viewModel = await load(FakeEntitlementProvider(environment: nil))
        #expect(viewModel.statusLine == "Not verified")
    }

    @Test func waivedEnvironmentReportsDevelopmentBuild() async {
        let viewModel = await load(FakeEntitlementProvider(environment: .sandbox))
        #expect(viewModel.statusLine == "TestFlight / development build")
    }

    @Test func productionWithNoSubscriptionReportsNoActiveSubscription() async {
        let viewModel = await load(FakeEntitlementProvider(environment: .production, subscription: nil))
        #expect(viewModel.statusLine == "No active subscription")
        #expect(viewModel.detailLine == nil)
    }

    @Test func activeMonthlySubscriptionRenews() async {
        let provider = FakeEntitlementProvider(
            environment: .production,
            subscription: snapshot(productId: Entitlement.Products.monthly, endsAfter: 20 * day)
        )
        let viewModel = await load(provider)
        #expect(viewModel.statusLine == "Monthly subscription")
        #expect(viewModel.detailLine?.hasPrefix("Renews") == true)
    }

    @Test func familySharedAnnualSubscriptionIsLabelled() async {
        let provider = FakeEntitlementProvider(
            environment: .production,
            subscription: snapshot(productId: Entitlement.Products.annual, endsAfter: 200 * day, isFamilyShared: true)
        )
        let viewModel = await load(provider)
        #expect(viewModel.statusLine.contains("Annual"))
        #expect(viewModel.statusLine.contains("Family Sharing"))
    }

    @Test func expiredSubscriptionShowsExpired() async {
        let provider = FakeEntitlementProvider(
            environment: .production,
            subscription: snapshot(productId: Entitlement.Products.monthly, endsAfter: -5 * day)
        )
        let viewModel = await load(provider)
        #expect(viewModel.detailLine?.hasPrefix("Expired") == true)
    }
}
