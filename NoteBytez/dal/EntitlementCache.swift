// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  EntitlementCache.swift
//  Kontinuum
//

import Foundation
import OSLog
import Security

/// The last successful entitlement verification, persisted so a previously-verified subscriber
/// keeps working offline for the 7-day window (Resolution G10). Stored in the Keychain, not
/// `UserDefaults`/a plist, because it is a security-relevant value (Resolution G20).
struct CachedEntitlement: Codable, Sendable, Equatable {
    /// When the last live StoreKit verification succeeded.
    var lastVerified: Date
    /// The verified subscription's expiry at that time, if known.
    var expirationDate: Date?
    /// The verified product id, if a subscription (not a waived environment) was the basis.
    var productId: String?
    /// The environment the verification ran in.
    var environment: EntitlementEnvironment
}

/// Read/write seam over the cached entitlement. Production uses `KeychainEntitlementCache`;
/// tests and previews use `InMemoryEntitlementCache`.
protocol EntitlementCaching: Sendable {
    func load() -> CachedEntitlement?
    func save(_ entitlement: CachedEntitlement)
    func clear()
}

/// Keychain-backed cache. `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — available in the
/// background for the `Transaction.updates` re-check, never migrated to a new device, never
/// synced to iCloud Keychain.
struct KeychainEntitlementCache: EntitlementCaching {

    private let service: String
    private let account: String
    private let logger = Log.logger(.entitlement)

    /// `service` is overridable so each `KeychainEntitlementCacheTests` case can use an isolated
    /// keychain item and clean it up, mirroring how the `UserDefaults`-backed stores take a
    /// suite name in their tests.
    init(service: String = "com.g9Consulting.Kontinuum.entitlement", account: String = "cachedEntitlement") {
        self.service = service
        self.account = account
    }

    func load() -> CachedEntitlement? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else {
            if status != errSecItemNotFound {
                logger.error("Keychain read failed: \(status)")
            }
            return nil
        }
        do {
            return try JSONDecoder().decode(CachedEntitlement.self, from: data)
        } catch {
            // A value we can't decode is as good as no value — and a stale schema shouldn't
            // wedge the gate, so drop it.
            logger.error("Cached entitlement failed to decode; discarding")
            clear()
            return nil
        }
    }

    func save(_ entitlement: CachedEntitlement) {
        guard let data = try? JSONEncoder().encode(entitlement) else {
            logger.error("Cached entitlement failed to encode; not persisted")
            return
        }

        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let updateStatus = SecItemUpdate(baseQuery as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var insert = baseQuery
            insert.merge(attributes) { _, new in new }
            let addStatus = SecItemAdd(insert as CFDictionary, nil)
            if addStatus != errSecSuccess {
                logger.error("Keychain insert failed: \(addStatus)")
            }
        } else if updateStatus != errSecSuccess {
            logger.error("Keychain update failed: \(updateStatus)")
        }
    }

    func clear() {
        let status = SecItemDelete(baseQuery as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            logger.error("Keychain delete failed: \(status)")
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}

/// In-memory cache for tests and SwiftUI previews. Thread-safe so it can stand in for the real
/// cache under the gate view model's concurrent `evaluate()` calls.
final class InMemoryEntitlementCache: EntitlementCaching, @unchecked Sendable {

    private let lock = NSLock()
    private var stored: CachedEntitlement?

    init(seed: CachedEntitlement? = nil) {
        self.stored = seed
    }

    func load() -> CachedEntitlement? {
        lock.withLock { stored }
    }

    func save(_ entitlement: CachedEntitlement) {
        lock.withLock { stored = entitlement }
    }

    func clear() {
        lock.withLock { stored = nil }
    }
}
