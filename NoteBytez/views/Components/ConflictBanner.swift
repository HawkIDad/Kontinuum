// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictBanner.swift
//  Kontinuum
//

import SwiftUI

/// Dismissible top-of-note strip for Strategy 2 (Last-Write-Wins) — shown both embedded atop
/// S4 for the specific note it applies to, and as S10's content region when that strategy is
/// active. "Newest edit wins; a banner lets you revert."
struct ConflictBanner: View {

    let resolution: ConflictAutoResolution
    let onRevert: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 6) {
                Text("Kept \(resolution.keptLabel) for \"\(resolution.conflict.title)\"")
                    .font(.callout)

                HStack {
                    Button("Revert", action: onRevert)
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Dismiss")
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

}
