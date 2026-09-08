// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SubscriptionActions.swift
//  NoteBytez
//

import SwiftUI
import StoreKit

/// Cross-platform "Manage Subscription" / "Redeem Code" affordances. iOS has first-party sheets
/// (`.manageSubscriptionsSheet`, `.offerCodeRedemption`); macOS has neither, so it falls back to
/// the App Store account pages. Kept in one place so `BlockedView`, `PaywallView`, and
/// `SubscriptionSettingsView` stay identical.
struct SubscriptionActionButtons: View {

    var includeRedeemCode = true

    @State private var isPresentingManageSubscriptions = false
    @State private var isPresentingRedeemCode = false
    @Environment(\.openURL) private var openURL

    var body: some View {
        Group {
            Button("Manage Subscription") {
                #if os(iOS)
                isPresentingManageSubscriptions = true
                #else
                openURL(Self.manageSubscriptionsURL)
                #endif
            }
            .accessibilityIdentifier("entitlement.manageSubscription")

            if includeRedeemCode {
                Button("Redeem Code") {
                    #if os(iOS)
                    isPresentingRedeemCode = true
                    #else
                    openURL(Self.redeemCodeURL)
                    #endif
                }
                .accessibilityIdentifier("entitlement.redeemCode")
            }
        }
        #if os(iOS)
        .manageSubscriptionsSheet(isPresented: $isPresentingManageSubscriptions)
        .offerCodeRedemption(isPresented: $isPresentingRedeemCode) { _ in }
        #endif
    }

    private static let manageSubscriptionsURL = URL(string: "https://apps.apple.com/account/subscriptions")!
    private static let redeemCodeURL = URL(string: "https://apps.apple.com/redeem")!
}
