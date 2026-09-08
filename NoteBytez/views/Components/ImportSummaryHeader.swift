// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportSummaryHeader.swift
//  Kontinuum
//

import SwiftUI

/// Aggregate counts (notes/links/tasks/notebooks), per docs/styleGuide.md — the trust-building
/// moment from Journey 1, shown before any commitment.
struct ImportSummaryHeader: View {

    let noteCount: Int
    let linkCount: Int
    let taskCount: Int
    let notebookCount: Int

    var body: some View {
        Text("\(noteCount) note\(noteCount == 1 ? "" : "s") · \(linkCount) wikilink\(linkCount == 1 ? "" : "s") · \(taskCount) task\(taskCount == 1 ? "" : "s") · \(notebookCount) notebook\(notebookCount == 1 ? "" : "s") found")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }

}
