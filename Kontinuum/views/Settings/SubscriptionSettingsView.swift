// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SubscriptionSettingsView.swift
//  Kontinuum
//

import SwiftUI

/// Settings → Subscription (NoteBytez20260907v1-Security.md Phase 6). Shows the current plan and
/// renewal date, and the App Review-required Restore / Manage / Redeem affordances (G21).
struct SubscriptionSettingsView: View {

    @State private var viewModel = SubscriptionSettingsViewModel()
    @State private var restoreViewModel = PaywallViewModel()
    @State private var isPresentingPaywall = false

    var body: some View {
        List {
            Section("Status") {
                Text(viewModel.statusLine)
                if let detailLine = viewModel.detailLine {
                    Text(detailLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Change or Start Subscription") { isPresentingPaywall = true }
                Button("Restore Purchases") {
                    Task { await restoreViewModel.restorePurchases() }
                }
                SubscriptionActionButtons(includeRedeemCode: true)
            } footer: {
                if let errorMessage = restoreViewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Subscription")
        .task { await viewModel.load() }
        .sheet(isPresented: $isPresentingPaywall) {
            PaywallView(
                onEntitled: {
                    isPresentingPaywall = false
                    Task { await viewModel.load() }
                },
                showsDoneButton: true
            )
        }
    }
}
