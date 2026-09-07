// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  UnlinkedMentionRow.swift
//  Kontinuum
//

import SwiftUI

/// Same as BacklinkRow, visually de-emphasized to distinguish from confirmed links,
/// per docs/styleGuide.md.
struct UnlinkedMentionRow: View {

    let match: BacklinkMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(match.sourceDocument.title ?? "Untitled")
                .font(.body)
                .foregroundStyle(.secondary)
            Text(match.snippet)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

}
