// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BlockReferenceText.swift
//  Kontinuum
//

import SwiftUI

/// Inline styled text run for a `((anchor))` block reference, tappable — per docs/styleGuide.md.
/// Used for the `((` autocomplete suggestion list, mirroring `WikilinkText`'s role for
/// wikilinks. Document body text renders block references through MDProcessor + Text instead,
/// same split `WikilinkText`/`TagChip` already establish for their own inline styles.
struct BlockReferenceText: View {

    let anchor: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("((\(anchor)))")
                .font(.callout.monospaced())
                .foregroundStyle(Color.accentColor)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}
