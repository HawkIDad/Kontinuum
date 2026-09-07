// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BacklinkRow.swift
//  Kontinuum
//

import SwiftUI

/// Source note title + matched snippet, per docs/styleGuide.md.
struct BacklinkRow: View {

    let match: BacklinkMatch

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(match.sourceDocument.title ?? "Untitled")
                .font(.body)
            Text(match.snippet)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

}
