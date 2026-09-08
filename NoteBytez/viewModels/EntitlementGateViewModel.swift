// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  EntitlementGateViewModel.swift
//  NoteBytez
//

import Foundation
import Observation
import OSLog

/// The state machine behind App Store provenance + subscription enforcement
/// (NoteBytez20260907v1-Security.md). Evaluated at launch, on foreground, on every
/// `Transaction.updates` event, and on a periodic foreground timer; produces one `AccessLevel`
/// that `EntitlementGateContainer` renders.
@MainActor
@Observable
final class EntitlementGateViewModel {

    /// The current resolved access state. Starts at a cache-only provisional value so a
    /// returning subscriber doesn't flash the paywall; `hasEvaluated` gates the real UI until
    /// the first live `evaluate()` completes.
    private(set) var accessLevel: AccessLevel

    /// `false` until the first `evaluate()` finishes — the container shows a spinner until then.
    private(set) var hasEvaluated = false

    private let provider: EntitlementProviding
    private let cache: EntitlementCaching
    private let syncEngine: SyncEngineControlling
    private let offlineWindow: TimeInterval
    private let postLapseGrace: TimeInterval
    private let now: () -> Date
    private let logger = Log.logger(.entitlement)

    private var observationTask: Task<Void, Never>?

    init(
        provider: EntitlementProviding = StoreKitEntitlementProvider(),
        cache: EntitlementCaching = KeychainEntitlementCache(),
        syncEngine: SyncEngineControlling = SyncEngine.shared,
        offlineWindow: TimeInterval = Entitlement.offlineCacheWindow,
        postLapseGrace: TimeInterval = Entitlement.postLapseGrace,
        now: @escaping () -> Date = { Date() }
    ) {
        self.provider = provider
        self.cache = cache
        self.syncEngine = syncEngine
        self.offlineWindow = offlineWindow
        self.postLapseGrace = postLapseGrace
        self.now = now
        self.accessLevel = Self.provisionalAccessLevel(
            cache: cache.load(),
            now: now(),
            offlineWindow: offlineWindow,
            postLapseGrace: postLapseGrace
        )
    }

    // MARK: - Lifecycle

    /// Runs the first `evaluate()` and then keeps re-evaluating on every `Transaction.updates`
    /// event. The view drives the additional foreground / timer triggers.
    func startObserving() {
        guard observationTask == nil else { return }
        observationTask = Task { [weak self] in
            guard let self else { return }
            await self.evaluate()
            for await _ in self.provider.transactionUpdates {
                if Task.isCancelled { return }
                await self.evaluate()
            }
        }
    }

    // MARK: - Evaluation

    /// Recomputes `accessLevel` from live StoreKit state plus the offline cache.
    func evaluate() async {
        let level = await computeAccessLevel()
        apply(level)
        hasEvaluated = true
    }

    /// The ordered decision table (NoteBytez20260907v1-Security.md Phase 3):
    ///  1. provenance fails            → blocked, no grace
    ///  2. `.sandbox` / `.xcode`       → full (TestFlight / dev; subscription waived)
    ///  3. active subscription         → full, refresh cache
    ///  4. cache within offline window → full
    ///  5. within post-lapse grace     → warning; past it → blocked (lapsed / offline-too-long)
    ///  6. nothing now, nothing cached → blocked (never subscribed → paywall)
    private func computeAccessLevel() async -> AccessLevel {
        guard let environment = await provider.verifyProvenance() else {
            return .blocked(reason: .provenanceFailed)
        }

        if environment.isSubscriptionWaived {
            return .full
        }

        let subscription = await provider.currentSubscription()
        if let subscription, subscription.isActive(asOf: now()) {
            cache.save(CachedEntitlement(
                lastVerified: now(),
                expirationDate: subscription.expirationDate,
                productId: subscription.productId,
                environment: environment
            ))
            return .full
        }

        let cached = cache.load()
        if let cached, now().timeIntervalSince(cached.lastVerified) <= offlineWindow {
            return .full
        }

        guard let lapseAnchor = Self.lapseAnchor(subscriptionEnd: Self.effectiveEnd(of: subscription), cached: cached) else {
            return .blocked(reason: .neverSubscribed)
        }

        let elapsed = now().timeIntervalSince(lapseAnchor)
        if elapsed <= postLapseGrace {
            let remaining = postLapseGrace - elapsed
            return .warning(daysRemaining: max(1, Int(ceil(remaining / 86_400))))
        }

        // Grace exhausted. If a subscription (live or previously cached) was ever the basis,
        // this is a lapse; otherwise the cache simply went stale offline.
        if subscription != nil || cached?.productId != nil {
            return .blocked(reason: .subscriptionLapsed)
        }
        return .blocked(reason: .offlineTooLong)
    }

    /// Applies the new level and drives sync suspend/resume across blocked ⇄ unblocked
    /// transitions. On the very first evaluation the side effect is forced to match the
    /// resolved state, since the engine may already have started (Phase 5).
    private func apply(_ level: AccessLevel) {
        let wasBlocked = accessLevel.isBlocked
        let isBlocked = level.isBlocked

        if accessLevel != level {
            logger.notice("Access level: \(String(describing: level), privacy: .public)")
        }
        accessLevel = level

        if !hasEvaluated {
            isBlocked ? syncEngine.suspend() : syncEngine.resume()
        } else if isBlocked && !wasBlocked {
            syncEngine.suspend()
        } else if !isBlocked && wasBlocked {
            syncEngine.resume()
        }
    }

    // MARK: - Pure helpers

    /// When a subscription effectively ended: its revocation date (refund / family-sharing
    /// removal) if revoked — clamped to the expiry when that is earlier — otherwise its expiry.
    nonisolated static func effectiveEnd(of subscription: SubscriptionSnapshot?) -> Date? {
        guard let subscription else { return nil }
        guard let revocationDate = subscription.revocationDate else { return subscription.expirationDate }
        return min(revocationDate, subscription.expirationDate ?? revocationDate)
    }

    /// Most recent of the known lapse points — the subscription's effective end, a cached
    /// expiry, or (failing both) the last verification time. `nil` only when nothing has ever
    /// been seen.
    nonisolated static func lapseAnchor(subscriptionEnd: Date?, cached: CachedEntitlement?) -> Date? {
        [subscriptionEnd, cached?.expirationDate, cached?.lastVerified]
            .compactMap { $0 }
            .max()
    }

    /// Synchronous, cache-only best guess used before the first live `evaluate()` — also the
    /// basis for suspending sync at launch (Phase 5).
    nonisolated static func provisionalAccessLevel(
        cache: CachedEntitlement?,
        now: Date,
        offlineWindow: TimeInterval,
        postLapseGrace: TimeInterval
    ) -> AccessLevel {
        guard let cache else { return .blocked(reason: .neverSubscribed) }

        if now.timeIntervalSince(cache.lastVerified) <= offlineWindow {
            return .full
        }

        let anchor = cache.expirationDate ?? cache.lastVerified
        let elapsed = now.timeIntervalSince(anchor)
        if elapsed <= postLapseGrace {
            return .warning(daysRemaining: max(1, Int(ceil((postLapseGrace - elapsed) / 86_400))))
        }
        return .blocked(reason: cache.productId != nil ? .subscriptionLapsed : .offlineTooLong)
    }

    /// Whether a launch should start `SyncEngine` already suspended (Phase 5) — read
    /// synchronously from the Keychain cache in `NoteBytezApp.init`.
    nonisolated static func launchShouldSuspendSync(cache: EntitlementCaching = KeychainEntitlementCache(), now: Date = Date()) -> Bool {
        provisionalAccessLevel(
            cache: cache.load(),
            now: now,
            offlineWindow: Entitlement.offlineCacheWindow,
            postLapseGrace: Entitlement.postLapseGrace
        ).isBlocked
    }

    /// The instance `EntitlementGateContainer` uses by default.
    ///
    /// Release: the real StoreKit-backed provider + Keychain cache.
    ///
    /// DEBUG: a development build is never gated, so the default resolves straight to `.full`.
    /// A `-SimulateEntitlement <scenario>` launch argument opts a run into the canned provider
    /// so UI tests and manual QA can drive every state without StoreKit (Phase 4 DEBUG seam).
    static func makeDefault() -> EntitlementGateViewModel {
        #if DEBUG
        let scenario = SimulatedEntitlementProvider.fromLaunchArguments()?.scenario ?? .full
        return EntitlementGateViewModel(
            provider: SimulatedEntitlementProvider(scenario: scenario),
            cache: InMemoryEntitlementCache()
        )
        #else
        return EntitlementGateViewModel()
        #endif
    }
}
