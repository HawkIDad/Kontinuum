// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LapsedBanner.swift
//  Kontinuum
//

import SwiftUI

/// Non-dismissable strip shown above the full app UI during the post-lapse grace window
/// (`AccessLevel.warning`). Orange + icon + text per `Docs/styleGuide.md`'s "color is never the
/// only signal" rule — this is a recoverable state, not catastrophic.
struct LapsedBanner: View {

    let daysRemaining: Int
    let onResubscribe: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
            Text(message)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button("Resubscribe", action: onResubscribe)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .accessibilityIdentifier("entitlement.resubscribe")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(.orange.opacity(0.15))
        .overlay(alignment: .bottom) { Divider() }
    }

    private var message: String {
        let dayWord = daysRemaining == 1 ? "day" : "days"
        return "Your NoteBytez subscription has lapsed — \(daysRemaining) \(dayWord) of access left."
    }
}
