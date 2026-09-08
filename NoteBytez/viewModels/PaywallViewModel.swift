// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PaywallViewModel.swift
//  NoteBytez
//

import Foundation
import Observation
import OSLog
import StoreKit

/// Loads the two `NoteBytez` subscription products and drives purchase / restore. Used by
/// `PaywallView` (blocked-state primary surface) and `SubscriptionSettingsView`.
@MainActor
@Observable
final class PaywallViewModel {

    private(set) var products: [Product] = []
    private(set) var isLoadingProducts = false
    private(set) var isPurchasing = false
    private(set) var errorMessage: String?

    /// Called after any action that may have changed entitlement (purchase, restore) so the
    /// gate can re-evaluate immediately rather than waiting for the next `Transaction.updates`.
    private let onEntitlementMayHaveChanged: () -> Void
    private let logger = Log.logger(.entitlement)

    init(onEntitlementMayHaveChanged: @escaping () -> Void = {}) {
        self.onEntitlementMayHaveChanged = onEntitlementMayHaveChanged
    }

    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            let loaded = try await Product.products(for: Entitlement.Products.all)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            logger.error("Product load failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn’t load subscription options. Check your connection and try again."
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        errorMessage = nil

        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                }
                onEntitlementMayHaveChanged()
            case .userCancelled:
                break
            case .pending:
                errorMessage = "Your purchase is pending approval. You’ll get access once it’s confirmed."
            @unknown default:
                break
            }
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "The purchase couldn’t be completed. Please try again."
        }
    }

    func restorePurchases() async {
        errorMessage = nil
        do {
            try await AppStore.sync()
        } catch {
            logger.error("Restore failed: \(error.localizedDescription, privacy: .public)")
            errorMessage = "Couldn’t restore purchases. Please try again."
        }
        onEntitlementMayHaveChanged()
    }
}
