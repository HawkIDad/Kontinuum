// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  StoreKitEntitlementProvider.swift
//  Kontinuum
//

import Foundation
import OSLog
import StoreKit

/// The live side of entitlement checking — everything that talks to StoreKit. On-device only:
/// `AppTransaction` proves App Store provenance of the install, `Transaction.currentEntitlements`
/// proves an active subscription. No server, no receipt-refresh endpoint, no jailbreak
/// heuristics (Resolution G5).
protocol EntitlementProviding: Sendable {

    /// The verified `AppTransaction` environment, or `nil` when the app transaction is
    /// unverified / unavailable (a patched or side-loaded binary).
    func verifyProvenance() async -> EntitlementEnvironment?

    /// The strongest currently-entitled auto-renewable subscription in the `NoteBytez` group,
    /// or `nil` when there is none.
    func currentSubscription() async -> SubscriptionSnapshot?

    /// Emits once per `Transaction.updates` event so the gate can re-evaluate on a purchase,
    /// renewal, refund, or family-sharing change.
    var transactionUpdates: AsyncStream<Void> { get }
}

struct StoreKitEntitlementProvider: EntitlementProviding {

    private let logger = Log.logger(.entitlement)

    func verifyProvenance() async -> EntitlementEnvironment? {
        do {
            let result = try await AppTransaction.shared
            guard case .verified(let appTransaction) = result else {
                logger.notice("App transaction is unverified — treating as failed provenance")
                return nil
            }
            return Self.map(appTransaction.environment)
        } catch {
            // On a legitimate first launch with no network the app transaction can be
            // momentarily unavailable; the gate falls back to the cache / grace path for that.
            logger.error("App transaction unavailable: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    func currentSubscription() async -> SubscriptionSnapshot? {
        var strongest: SubscriptionSnapshot?

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            guard transaction.productType == .autoRenewable else { continue }
            guard Entitlement.Products.all.contains(transaction.productID) else { continue }

            let snapshot = SubscriptionSnapshot(
                productId: transaction.productID,
                expirationDate: transaction.expirationDate,
                isFamilyShared: transaction.ownershipType == .familyShared,
                isInAppleGracePeriod: await isInAppleGracePeriod(transaction),
                revocationDate: transaction.revocationDate
            )

            let candidateExpiry = snapshot.expirationDate ?? .distantPast
            let strongestExpiry = strongest?.expirationDate ?? .distantPast
            if strongest == nil || candidateExpiry >= strongestExpiry {
                strongest = snapshot
            }
        }

        return strongest
    }

    var transactionUpdates: AsyncStream<Void> {
        AsyncStream { continuation in
            let task = Task {
                for await update in Transaction.updates {
                    if case .verified(let transaction) = update {
                        await transaction.finish()
                    }
                    continuation.yield(())
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Helpers

    private func isInAppleGracePeriod(_ transaction: Transaction) async -> Bool {
        guard let status = await transaction.subscriptionStatus else { return false }
        return status.state == .inGracePeriod
    }

    private static func map(_ environment: AppStore.Environment) -> EntitlementEnvironment {
        switch environment {
        case .production: return .production
        case .sandbox: return .sandbox
        case .xcode: return .xcode
        default: return .production
        }
    }
}
