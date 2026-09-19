// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookListRow.swift
//  NoteBytez
//

import SwiftUI

/// Notebook name + document count, per docs/styleGuide.md.
struct NotebookListRow: View {

    let name: String
    let documentCount: Int

    var body: some View {
        HStack {
            Image(systemName: "books.vertical")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(name)
                .font(.body)
            Spacer()
            Text(String(localized: "\(documentCount) document"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

}
