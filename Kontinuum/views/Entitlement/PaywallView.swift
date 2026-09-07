// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PaywallView.swift
//  Kontinuum
//

import SwiftUI
import StoreKit
import UniformTypeIdentifiers

/// Blocked-state primary surface for a user who has never subscribed (`BlockReason.neverSubscribed`),
/// and the sheet `BlockedView` / `LapsedBanner` present to resubscribe. Lists the Monthly +
/// Annual products, purchases, and always offers Restore Purchases + a read-only export
/// (NoteBytez20260907v1-Security.md G14, G16, G21).
struct PaywallView: View {

    let onEntitled: () -> Void
    /// When shown as a sheet from `BlockedView` / `LapsedBanner` rather than as the root surface.
    var showsDoneButton = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var paywallViewModel: PaywallViewModel?
    @State private var blockedViewModel: BlockedViewModel?
    @State private var isPresentingExportPicker = false

    // TODO(product-owner): real Terms of Use (EULA) + Privacy Policy URLs — deferred item in
    // NoteBytez20260907v1-Security.md.
    private let termsURL = URL(string: "https://notebytez.app/terms")!
    private let privacyURL = URL(string: "https://notebytez.app/privacy")!

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subscribe to NoteBytez")
                            .font(.title2.bold())
                            .accessibilityIdentifier("entitlement.paywall.title")
                        Text("Start with a free trial. Your subscription unlocks every device signed into your Apple Account, and your family through Family Sharing.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    subscriptionOptions

                    VStack(spacing: 12) {
                        Button("Restore Purchases") {
                            Task { await paywallViewModel?.restorePurchases() }
                        }
                        .accessibilityIdentifier("entitlement.restorePurchases")

                        SubscriptionActionButtons(includeRedeemCode: true)

                        Button("Export My Notes") { isPresentingExportPicker = true }
                            .accessibilityIdentifier("entitlement.exportNotes")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 6) {
                        Link("Terms of Use", destination: termsURL)
                        Link("Privacy Policy", destination: privacyURL)
                        Text("Payment is charged to your Apple Account. Subscriptions renew automatically unless cancelled at least 24 hours before the end of the period. Manage or cancel in Settings.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let errorMessage = paywallViewModel?.errorMessage {
                        Text(errorMessage).foregroundStyle(.red)
                    }
                    if let exportMessage = blockedViewModel?.exportResultMessage {
                        Text(exportMessage).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: 520, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .navigationTitle("NoteBytez")
            .toolbar {
                if showsDoneButton {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
        }
        .task {
            if paywallViewModel == nil {
                paywallViewModel = PaywallViewModel(onEntitlementMayHaveChanged: onEntitled)
            }
            if blockedViewModel == nil {
                blockedViewModel = BlockedViewModel(modelContext: modelContext)
            }
            await paywallViewModel?.loadProducts()
        }
        .fileImporter(isPresented: $isPresentingExportPicker, allowedContentTypes: [.folder]) { result in
            guard case .success(let folderURL) = result else { return }
            blockedViewModel?.exportAll(to: folderURL)
        }
    }

    @ViewBuilder
    private var subscriptionOptions: some View {
        if let paywallViewModel, !paywallViewModel.products.isEmpty {
            VStack(spacing: 10) {
                ForEach(paywallViewModel.products, id: \.id) { product in
                    Button {
                        Task { await paywallViewModel.purchase(product) }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(product.displayName).font(.headline)
                                Text(product.description).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(product.displayPrice).font(.body.monospacedDigit())
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(paywallViewModel.isPurchasing)
                    .accessibilityIdentifier("entitlement.buy.\(product.id)")
                }
            }
        } else if paywallViewModel?.isLoadingProducts == true {
            ProgressView()
        } else {
            Text("Subscription options are unavailable right now.")
                .foregroundStyle(.secondary)
        }
    }
}
