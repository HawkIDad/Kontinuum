// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagChip.swift
//  NoteBytez
//

import SwiftUI

/// Inline styled text run for a `#tag`, tappable — per docs/styleGuide.md. Used both for the
/// `#` autocomplete suggestion list (mirroring `WikilinkText`'s role for wikilinks) and for
/// the current document's tag row in S4. Deliberately plain text, not a filled capsule pill —
/// that's Obsidian's specific inline-tag treatment, and this app's tag/wikilink grammar should
/// read as one family (see `WikilinkText`), not borrow a competitor's chip styling.
struct TagChip: View {

    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("#\(name)")
                .font(.callout)
                .foregroundStyle(Color.accentColor)
                // Height only, not width — this sits inline in a packed horizontal row.
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}
