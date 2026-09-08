// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  WikilinkText.swift
//  NoteBytez
//

import SwiftUI

/// Styled, tappable text run for a `[[wikilink]]` title, per docs/styleGuide.md. Document
/// body text renders wikilinks through MDProcessor + Text instead (consistent with every
/// other inline Markdown style); this component is for standalone contexts such as a
/// wikilink autocomplete suggestion.
struct WikilinkText: View {

    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundStyle(Color.accentColor)
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}
