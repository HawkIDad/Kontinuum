// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PromoteSourcePreview.swift
//  NoteBytez
//

import SwiftUI

/// Read-only snippet of the journal block being promoted, so the user confirms exactly what's
/// moving before committing — per UIUX/05-Wireframes.md's S15. Unlike a search/backlink
/// snippet, this is the actual content being acted on, so it isn't line-limited: clipping it
/// would let a user confirm a promote without seeing everything that's about to move.
struct PromoteSourcePreview: View {

    let content: String

    var body: some View {
        Text(content)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.noteBytezSecondarySurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

}
