// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportSummaryHeader.swift
//  NoteBytez
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
        Text(summaryText)
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
    }

    /// Composed from four independently plural-correct fragments (G14) rather than one literal
    /// with four inline ternaries — each count gets its own String Catalog plural variation.
    private var summaryText: String {
        let notes = String(localized: "\(noteCount) note")
        let links = String(localized: "\(linkCount) wikilink")
        let tasks = String(localized: "\(taskCount) task")
        let notebooks = String(localized: "\(notebookCount) notebook")
        return String(localized: "\(notes) · \(links) · \(tasks) · \(notebooks) found")
    }

}
