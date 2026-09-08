// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  EntitlementGateViewModelTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

// MARK: - Test doubles

/// Mutable so the blocked ⇄ unblocked transition tests can change the answer mid-lifecycle.
final class FakeEntitlementProvider: EntitlementProviding, @unchecked Sendable {
    var environment: EntitlementEnvironment?
    var subscription: SubscriptionSnapshot?

    init(environment: EntitlementEnvironment? = .production, subscription: SubscriptionSnapshot? = nil) {
        self.environment = environment
        self.subscription = subscription
    }

    func verifyProvenance() async -> EntitlementEnvironment? { environment }
    func currentSubscription() async -> SubscriptionSnapshot? { subscription }
    var transactionUpdates: AsyncStream<Void> { AsyncStream { $0.finish() } }
}

final class FakeSyncEngineControl: SyncEngineControlling, @unchecked Sendable {
    private(set) var suspendCount = 0
    private(set) var resumeCount = 0
    func suspend() { suspendCount += 1 }
    func resume() { resumeCount += 1 }
}

/// Advanceable clock so transition tests can move time forward between `evaluate()` calls.
final class MutableClock: @unchecked Sendable {
    var date: Date
    init(_ date: Date) { self.date = date }
}

// MARK: - Tests

@MainActor
struct EntitlementGateViewModelTests {

    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
    private let day: TimeInterval = 24 * 60 * 60

    private func snapshot(
        endsAfter offset: TimeInterval,
        isFamilyShared: Bool = false,
        isInAppleGracePeriod: Bool = false,
        revokedAfter revocationOffset: TimeInterval? = nil
    ) -> SubscriptionSnapshot {
        SubscriptionSnapshot(
            productId: Entitlement.Products.monthly,
            expirationDate: t0.addingTimeInterval(offset),
            isFamilyShared: isFamilyShared,
            isInAppleGracePeriod: isInAppleGracePeriod,
            revocationDate: revocationOffset.map { t0.addingTimeInterval($0) }
        )
    }

    private func makeViewModel(
        environment: EntitlementEnvironment? = .production,
        subscription: SubscriptionSnapshot? = nil,
        cache: EntitlementCaching = InMemoryEntitlementCache(),
        sync: FakeSyncEngineControl = FakeSyncEngineControl()
    ) -> (EntitlementGateViewModel, FakeEntitlementProvider, FakeSyncEngineControl, EntitlementCaching) {
        let provider = FakeEntitlementProvider(environment: environment, subscription: subscription)
        let viewModel = EntitlementGateViewModel(
            provider: provider,
            cache: cache,
            syncEngine: sync,
            now: { self.t0 }
        )
        return (viewModel, provider, sync, cache)
    }

    // MARK: 1 — provenance

    @Test func provenanceFailureBlocksWithNoGraceAndSuspendsSync() async {
        let (viewModel, _, sync, _) = makeViewModel(environment: nil)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .blocked(reason: .provenanceFailed))
        #expect(sync.suspendCount == 1)
        #expect(viewModel.hasEvaluated)
    }

    // MARK: 2 — waived environments

    @Test func sandboxEnvironmentIsFullEvenWithNoSubscription() async {
        let (viewModel, _, _, _) = makeViewModel(environment: .sandbox, subscription: nil)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .full)
    }

    @Test func xcodeEnvironmentIsFull() async {
        let (viewModel, _, _, _) = makeViewModel(environment: .xcode, subscription: nil)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .full)
    }

    // MARK: 3 — active subscription

    @Test func activeSubscriptionIsFullAndRefreshesCache() async {
        let cache = InMemoryEntitlementCache()
        let (viewModel, _, _, _) = makeViewModel(subscription: snapshot(endsAfter: 10 * day), cache: cache)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .full)
        #expect(cache.load()?.productId == Entitlement.Products.monthly)
        #expect(cache.load()?.lastVerified == t0)
    }

    @Test func familySharedSubscriptionIsFull() async {
        let (viewModel, _, _, _) = makeViewModel(subscription: snapshot(endsAfter: 5 * day, isFamilyShared: true))
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .full)
    }

    @Test func appleBillingGracePeriodIsFull() async {
        let (viewModel, _, _, _) = makeViewModel(subscription: snapshot(endsAfter: -day, isInAppleGracePeriod: true))
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .full)
    }

    // MARK: 4 — offline cache window

    @Test func offlineWithinWindowIsFull() async {
        let cache = InMemoryEntitlementCache(seed: CachedEntitlement(
            lastVerified: t0.addingTimeInterval(-6 * day), expirationDate: nil,
            productId: Entitlement.Products.monthly, environment: .production
        ))
        let (viewModel, _, _, _) = makeViewModel(subscription: nil, cache: cache)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .full)
    }

    @Test func offlineExactlyAtWindowBoundaryIsFull() async {
        let cache = InMemoryEntitlementCache(seed: CachedEntitlement(
            lastVerified: t0.addingTimeInterval(-Entitlement.offlineCacheWindow), expirationDate: nil,
            productId: Entitlement.Products.monthly, environment: .production
        ))
        let (viewModel, _, _, _) = makeViewModel(subscription: nil, cache: cache)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .full)
    }

    @Test func offlineOneSecondPastWindowWithCachedProductIsBlockedLapsed() async {
        let cache = InMemoryEntitlementCache(seed: CachedEntitlement(
            lastVerified: t0.addingTimeInterval(-Entitlement.offlineCacheWindow - 1), expirationDate: nil,
            productId: Entitlement.Products.monthly, environment: .production
        ))
        let (viewModel, _, sync, _) = makeViewModel(subscription: nil, cache: cache)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .blocked(reason: .subscriptionLapsed))
        #expect(sync.suspendCount == 1)
    }

    @Test func offlinePastWindowWithNoCachedProductIsBlockedOfflineTooLong() async {
        let cache = InMemoryEntitlementCache(seed: CachedEntitlement(
            lastVerified: t0.addingTimeInterval(-30 * day), expirationDate: nil,
            productId: nil, environment: .production
        ))
        let (viewModel, _, _, _) = makeViewModel(subscription: nil, cache: cache)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .blocked(reason: .offlineTooLong))
    }

    // MARK: 5 — post-lapse grace

    @Test func expiredSubscriptionWithinGraceIsWarning() async {
        let (viewModel, _, _, _) = makeViewModel(subscription: snapshot(endsAfter: -day))
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .warning(daysRemaining: 2))
    }

    @Test func gracePeriodBoundaryExactlyThreeDaysIsStillWarning() async {
        let (viewModel, _, _, _) = makeViewModel(subscription: snapshot(endsAfter: -Entitlement.postLapseGrace))
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .warning(daysRemaining: 1))
    }

    @Test func gracePeriodOneSecondPastThreeDaysIsBlocked() async {
        let (viewModel, _, _, _) = makeViewModel(subscription: snapshot(endsAfter: -Entitlement.postLapseGrace - 1))
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .blocked(reason: .subscriptionLapsed))
    }

    @Test func refundWithinGraceIsWarning() async {
        let (viewModel, _, _, _) = makeViewModel(subscription: snapshot(endsAfter: 10 * day, revokedAfter: -day))
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .warning(daysRemaining: 2))
    }

    @Test func refundPastGraceIsBlocked() async {
        let (viewModel, _, _, _) = makeViewModel(subscription: snapshot(endsAfter: 10 * day, revokedAfter: -5 * day))
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .blocked(reason: .subscriptionLapsed))
    }

    // MARK: 6 — never subscribed

    @Test func neverSubscribedNoCacheIsBlockedNeverSubscribed() async {
        let (viewModel, _, _, _) = makeViewModel(subscription: nil)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .blocked(reason: .neverSubscribed))
    }

    // MARK: transitions

    @Test func fullToBlockedSuspendsSyncExactlyOnce() async {
        // Active subscription ends 10 days out; the first check caches that expiry. Advancing
        // the clock past expiry + the 7-day offline window + the 3-day grace is what finally
        // blocks — the cache deliberately masks a lapse until it goes stale.
        let clock = MutableClock(t0)
        let provider = FakeEntitlementProvider(environment: .production, subscription: snapshot(endsAfter: 10 * day))
        let sync = FakeSyncEngineControl()
        let viewModel = EntitlementGateViewModel(
            provider: provider, cache: InMemoryEntitlementCache(), syncEngine: sync, now: { clock.date }
        )

        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .full)

        clock.date = t0.addingTimeInterval(14 * day) // past expiry (10d) + grace (3d)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .blocked(reason: .subscriptionLapsed))
        #expect(sync.suspendCount == 1)

        await viewModel.evaluate()
        #expect(sync.suspendCount == 1, "a repeat blocked evaluation must not re-suspend")
    }

    @Test func blockedToFullResumesSync() async {
        let (viewModel, provider, sync, _) = makeViewModel(subscription: nil)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel.isBlocked)
        let resumesAfterBlock = sync.resumeCount

        provider.subscription = snapshot(endsAfter: 10 * day)
        await viewModel.evaluate()
        #expect(viewModel.accessLevel == .full)
        #expect(sync.resumeCount > resumesAfterBlock)
    }

    @Test func hasEvaluatedFlipsOnFirstEvaluation() async {
        let (viewModel, _, _, _) = makeViewModel(subscription: snapshot(endsAfter: day))
        #expect(viewModel.hasEvaluated == false)
        await viewModel.evaluate()
        #expect(viewModel.hasEvaluated)
    }
}
