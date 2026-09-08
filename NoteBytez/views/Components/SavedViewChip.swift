// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedViewChip.swift
//  Kontinuum
//

import SwiftUI

/// Pinned query name + type (search/task), tappable, per docs/styleGuide.md — always
/// re-evaluates live on tap, never shows a cached result count.
struct SavedViewChip: View {

    let savedView: SavedView
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(savedView.name ?? "Untitled", systemImage: savedView.savedQueryType == .task ? "checklist" : "magnifyingglass")
                .font(.callout)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

}
