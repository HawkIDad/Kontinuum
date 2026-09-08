// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Entitlement.swift
//  Kontinuum
//

import Foundation

/// App Store provenance + auto-renewable-subscription enforcement (NoteBytez20260907v1-Security.md).
/// These are plain value types — never a `@Model`, never synced. The gate that consumes them is
/// `EntitlementGateViewModel`; the sources are `StoreKitEntitlementProvider` (live) and
/// `EntitlementCache` (the last-good result, for the offline window).
enum Entitlement {

    /// The two auto-renewable products in the `NoteBytez` subscription group (Phase 0). A live
    /// transaction for any other product id is ignored by the gate.
    enum Products {
        static let monthly = "com.g9Consulting.NoteBytez.sub.monthly"
        static let annual = "com.g9Consulting.NoteBytez.sub.annual"
        static let all: Set<String> = [monthly, annual]
    }

    /// 7-day offline cache window and 3-day post-lapse grace (Resolution G12). Exposed here so
    /// production code and tests share one definition.
    static let offlineCacheWindow: TimeInterval = 7 * 24 * 60 * 60
    static let postLapseGrace: TimeInterval = 3 * 24 * 60 * 60
}

/// Which StoreKit environment the running build was signed / purchased through. `.sandbox`
/// (TestFlight, `.storekit` file) and `.xcode` (run-from-Xcode) are inherently store-provenanced,
/// so the subscription requirement is waived for both (Resolution G8).
enum EntitlementEnvironment: String, Sendable, Codable, CaseIterable {
    case production
    case sandbox
    case xcode

    /// TestFlight / Xcode / local `.storekit` — provenance is proven and no paid subscription
    /// is required.
    var isSubscriptionWaived: Bool {
        self != .production
    }
}

/// A point-in-time read of the user's auto-renewable subscription — `Transaction`
/// `currentEntitlements` plus `Product.SubscriptionInfo.Status`, distilled to just the fields the
/// gate's state machine needs.
struct SubscriptionSnapshot: Sendable, Equatable {

    let productId: String
    /// `nil` only for a transaction StoreKit reports without an expiry (not expected for an
    /// auto-renewable) — treated as "no known expiry", which is never a basis for `.full`.
    let expirationDate: Date?
    /// `Transaction.ownershipType == .familyShared` — accepted exactly like `.purchased`
    /// (Resolution G3).
    let isFamilyShared: Bool
    /// Apple's own billing grace period (`RenewalState.inGracePeriod`). Treated as fully
    /// entitled (Resolution G13).
    let isInAppleGracePeriod: Bool
    /// Non-`nil` once Apple has revoked the purchase (refund, or removal from a family group).
    /// Forces re-lock regardless of `expirationDate` (Resolution G11).
    let revocationDate: Date?

    /// Whether this snapshot, evaluated against `now`, still grants access.
    func isActive(asOf now: Date) -> Bool {
        guard revocationDate == nil else { return false }
        if isInAppleGracePeriod { return true }
        guard let expirationDate else { return false }
        return expirationDate > now
    }
}

/// Why the app is in its blocked state — drives which screen the container shows and the copy
/// on it.
enum BlockReason: String, Sendable, Equatable, CaseIterable {
    /// The install is not from the App Store / TestFlight / Xcode (patched or side-loaded
    /// binary). No grace period (Resolution G1).
    case provenanceFailed
    /// No subscription now and none ever cached — show the paywall, not the data-export screen
    /// (Resolution G14).
    case neverSubscribed
    /// Had a subscription, it ended, and the 3-day post-lapse grace is exhausted (Resolution G11).
    case subscriptionLapsed
    /// Was verified once, but the cache is older than the 7-day offline window and StoreKit
    /// could not be reached to re-verify (Resolution G10).
    case offlineTooLong
}

/// The resolved access state. Exactly three levels — the container renders app UI, app UI plus
/// a lapse banner, or a block / paywall screen.
enum AccessLevel: Sendable, Equatable {
    case full
    case warning(daysRemaining: Int)
    case blocked(reason: BlockReason)

    var isBlocked: Bool {
        if case .blocked = self { return true }
        return false
    }
}
