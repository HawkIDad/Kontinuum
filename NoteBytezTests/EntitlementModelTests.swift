// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  EntitlementModelTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

/// Pure value-type behaviour behind the entitlement gate — no StoreKit, no cache, no clock.
struct EntitlementModelTests {

    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    // MARK: - EntitlementEnvironment

    @Test func onlyProductionRequiresASubscription() {
        #expect(EntitlementEnvironment.production.isSubscriptionWaived == false)
        #expect(EntitlementEnvironment.sandbox.isSubscriptionWaived)
        #expect(EntitlementEnvironment.xcode.isSubscriptionWaived)
    }

    // MARK: - SubscriptionSnapshot.isActive

    @Test func futureExpiryIsActive() {
        let snapshot = makeSnapshot(expirationDate: now.addingTimeInterval(day))
        #expect(snapshot.isActive(asOf: now))
    }

    @Test func pastExpiryIsNotActive() {
        let snapshot = makeSnapshot(expirationDate: now.addingTimeInterval(-day))
        #expect(snapshot.isActive(asOf: now) == false)
    }

    @Test func appleGracePeriodIsActiveEvenWithPastExpiry() {
        let snapshot = makeSnapshot(expirationDate: now.addingTimeInterval(-day), isInAppleGracePeriod: true)
        #expect(snapshot.isActive(asOf: now))
    }

    @Test func revokedIsNeverActiveEvenWithFutureExpiry() {
        let snapshot = makeSnapshot(expirationDate: now.addingTimeInterval(10 * day), revocationDate: now)
        #expect(snapshot.isActive(asOf: now) == false)
    }

    @Test func missingExpiryIsNotActive() {
        let snapshot = makeSnapshot(expirationDate: nil)
        #expect(snapshot.isActive(asOf: now) == false)
    }

    // MARK: - effectiveEnd

    @Test func effectiveEndIsExpiryWhenNotRevoked() {
        let expiry = now.addingTimeInterval(day)
        #expect(EntitlementGateViewModel.effectiveEnd(of: makeSnapshot(expirationDate: expiry)) == expiry)
    }

    @Test func effectiveEndIsRevocationWhenRevokedBeforeExpiry() {
        let revoked = now
        let snapshot = makeSnapshot(expirationDate: now.addingTimeInterval(10 * day), revocationDate: revoked)
        #expect(EntitlementGateViewModel.effectiveEnd(of: snapshot) == revoked)
    }

    @Test func effectiveEndIsNilForNoSubscription() {
        #expect(EntitlementGateViewModel.effectiveEnd(of: nil) == nil)
    }

    // MARK: - lapseAnchor

    @Test func lapseAnchorPrefersTheMostRecentKnownPoint() {
        let cached = CachedEntitlement(
            lastVerified: now.addingTimeInterval(-5 * day),
            expirationDate: now.addingTimeInterval(-2 * day),
            productId: Entitlement.Products.monthly,
            environment: .production
        )
        let anchor = EntitlementGateViewModel.lapseAnchor(subscriptionEnd: now.addingTimeInterval(-day), cached: cached)
        #expect(anchor == now.addingTimeInterval(-day))
    }

    @Test func lapseAnchorIsNilWhenNothingIsKnown() {
        #expect(EntitlementGateViewModel.lapseAnchor(subscriptionEnd: nil, cached: nil) == nil)
    }

    // MARK: - AccessLevel

    @Test func isBlockedOnlyForTheBlockedCase() {
        #expect(AccessLevel.full.isBlocked == false)
        #expect(AccessLevel.warning(daysRemaining: 2).isBlocked == false)
        #expect(AccessLevel.blocked(reason: .subscriptionLapsed).isBlocked)
    }

    // MARK: - provisionalAccessLevel

    @Test func provisionalIsNeverSubscribedWithNoCache() {
        let level = EntitlementGateViewModel.provisionalAccessLevel(
            cache: nil, now: now, offlineWindow: Entitlement.offlineCacheWindow, postLapseGrace: Entitlement.postLapseGrace
        )
        #expect(level == .blocked(reason: .neverSubscribed))
    }

    @Test func provisionalIsFullWithinTheOfflineWindow() {
        let cache = CachedEntitlement(lastVerified: now.addingTimeInterval(-day), expirationDate: nil, productId: Entitlement.Products.annual, environment: .production)
        let level = EntitlementGateViewModel.provisionalAccessLevel(
            cache: cache, now: now, offlineWindow: Entitlement.offlineCacheWindow, postLapseGrace: Entitlement.postLapseGrace
        )
        #expect(level == .full)
    }

    @Test func provisionalIsLapsedWhenStaleAndAProductWasCached() {
        let cache = CachedEntitlement(lastVerified: now.addingTimeInterval(-30 * day), expirationDate: now.addingTimeInterval(-20 * day), productId: Entitlement.Products.monthly, environment: .production)
        let level = EntitlementGateViewModel.provisionalAccessLevel(
            cache: cache, now: now, offlineWindow: Entitlement.offlineCacheWindow, postLapseGrace: Entitlement.postLapseGrace
        )
        #expect(level == .blocked(reason: .subscriptionLapsed))
    }

    // MARK: - Helpers

    private func makeSnapshot(
        expirationDate: Date?,
        isFamilyShared: Bool = false,
        isInAppleGracePeriod: Bool = false,
        revocationDate: Date? = nil
    ) -> SubscriptionSnapshot {
        SubscriptionSnapshot(
            productId: Entitlement.Products.monthly,
            expirationDate: expirationDate,
            isFamilyShared: isFamilyShared,
            isInAppleGracePeriod: isInAppleGracePeriod,
            revocationDate: revocationDate
        )
    }
}
