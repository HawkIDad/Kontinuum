// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  EntitlementCacheTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

/// `InMemoryEntitlementCache` (used everywhere else in tests) and the real
/// `KeychainEntitlementCache`, each with an isolated backing item — mirrors how the
/// `UserDefaults`-backed stores take a unique suite name in their own tests.
struct EntitlementCacheTests {

    private func sample(lastVerified: Date = Date(timeIntervalSince1970: 1_800_000_000)) -> CachedEntitlement {
        CachedEntitlement(
            lastVerified: lastVerified,
            expirationDate: lastVerified.addingTimeInterval(30 * 24 * 60 * 60),
            productId: Entitlement.Products.annual,
            environment: .production
        )
    }

    // MARK: - CachedEntitlement Codable

    @Test func cachedEntitlementRoundTripsThroughJSON() throws {
        let original = sample()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CachedEntitlement.self, from: data)
        #expect(decoded == original)
    }

    // MARK: - InMemoryEntitlementCache

    @Test func inMemoryStartsEmptyAndRoundTrips() {
        let cache = InMemoryEntitlementCache()
        #expect(cache.load() == nil)

        let entitlement = sample()
        cache.save(entitlement)
        #expect(cache.load() == entitlement)

        cache.clear()
        #expect(cache.load() == nil)
    }

    @Test func inMemorySeedIsReturnedImmediately() {
        let seeded = sample()
        let cache = InMemoryEntitlementCache(seed: seeded)
        #expect(cache.load() == seeded)
    }

    // MARK: - KeychainEntitlementCache

    @Test func keychainRoundTripsAndClears() {
        let cache = KeychainEntitlementCache(service: "KeychainEntitlementCacheTests-\(UUID().uuidString)")
        defer { cache.clear() }

        #expect(cache.load() == nil)

        let entitlement = sample()
        cache.save(entitlement)
        #expect(cache.load() == entitlement)

        cache.clear()
        #expect(cache.load() == nil)
    }

    @Test func keychainSaveOverwritesThePreviousValue() {
        let cache = KeychainEntitlementCache(service: "KeychainEntitlementCacheTests-\(UUID().uuidString)")
        defer { cache.clear() }

        cache.save(sample(lastVerified: Date(timeIntervalSince1970: 1_000_000_000)))
        let newer = sample(lastVerified: Date(timeIntervalSince1970: 1_900_000_000))
        cache.save(newer)

        #expect(cache.load() == newer)
    }
}
