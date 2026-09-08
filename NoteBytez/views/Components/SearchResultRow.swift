// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SearchResultRow.swift
//  Kontinuum
//

import SwiftUI

/// Title + matched-text snippet, per docs/styleGuide.md.
struct SearchResultRow: View {

    let title: String
    let snippet: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.isEmpty ? "Untitled" : title)
                .font(.body)
            if !snippet.isEmpty {
                Text(snippet)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

}
