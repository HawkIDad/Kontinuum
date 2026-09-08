// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BlockedView.swift
//  NoteBytez
//

import SwiftUI
import UniformTypeIdentifiers

/// Full-screen block for a user who had access and lost it (`subscriptionLapsed`,
/// `offlineTooLong`) or whose install failed provenance (`provenanceFailed`). Their notes are
/// untouched on disk; this screen always offers a read-only export and a path back
/// (NoteBytez20260907v1-Security.md G16, G21).
struct BlockedView: View {

    let reason: BlockReason
    let onResolved: () -> Void

    @Environment(\.modelContext) private var modelContext

    @State private var blockedViewModel: BlockedViewModel?
    @State private var isPresentingPaywall = false
    @State private var isPresentingExportPicker = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: iconName)
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("entitlement.blocked.title")

            Text(explanation)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            VStack(spacing: 12) {
                if reason != .provenanceFailed {
                    Button("Resubscribe") { isPresentingPaywall = true }
                        .buttonStyle(.borderedProminent)
                        .accessibilityIdentifier("entitlement.resubscribe")
                }

                Button("Restore Purchases") {
                    Task {
                        let restoreViewModel = PaywallViewModel(onEntitlementMayHaveChanged: onResolved)
                        await restoreViewModel.restorePurchases()
                    }
                }
                .accessibilityIdentifier("entitlement.restorePurchases")

                SubscriptionActionButtons(includeRedeemCode: true)

                Button("Export My Notes") { isPresentingExportPicker = true }
                    .accessibilityIdentifier("entitlement.exportNotes")
            }
            .padding(.top, 4)

            if let exportMessage = blockedViewModel?.exportResultMessage {
                Text(exportMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if reason == .provenanceFailed {
                Text("If you bought NoteBytez on the App Store, delete this copy and reinstall it from the App Store.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .frame(maxWidth: 480)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if blockedViewModel == nil {
                blockedViewModel = BlockedViewModel(modelContext: modelContext)
            }
        }
        .sheet(isPresented: $isPresentingPaywall) {
            PaywallView(onEntitled: {
                isPresentingPaywall = false
                onResolved()
            }, showsDoneButton: true)
        }
        .fileImporter(isPresented: $isPresentingExportPicker, allowedContentTypes: [.folder]) { result in
            guard case .success(let folderURL) = result else { return }
            blockedViewModel?.exportAll(to: folderURL)
        }
    }

    private var iconName: String {
        reason == .provenanceFailed ? "exclamationmark.shield" : "lock"
    }

    private var title: String {
        switch reason {
        case .provenanceFailed: return "This copy can’t be verified"
        case .subscriptionLapsed: return "Your subscription has ended"
        case .offlineTooLong: return "Please reconnect to continue"
        case .neverSubscribed: return "Subscribe to continue"
        }
    }

    private var explanation: String {
        switch reason {
        case .provenanceFailed:
            return "NoteBytez couldn’t confirm this app was installed from the App Store. Your notes are safe on this device and can still be exported below."
        case .subscriptionLapsed:
            return "Your grace period is over. Resubscribe to pick up exactly where you left off — nothing has been deleted."
        case .offlineTooLong:
            return "It’s been a while since NoteBytez could verify your subscription. Connect to the internet once to unlock again. Your notes are safe and can still be exported below."
        case .neverSubscribed:
            return "Start your free trial to use NoteBytez."
        }
    }
}
