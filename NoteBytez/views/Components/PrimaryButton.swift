// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PrimaryButton.swift
//  Kontinuum
//

import SwiftUI

/// Filled, accent-colored button — one per screen max, per docs/styleGuide.md.
struct PrimaryButton: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .accessibilityIdentifier("primaryButton.\(title)")
    }

}
