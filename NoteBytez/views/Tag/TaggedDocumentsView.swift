// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaggedDocumentsView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData

/// Notes carrying a given tag — a minimal stand-in for S7 Search Results' tag-filter scope
/// (per UIUX/05-Wireframes.md's S13 spec: "tap a tag to jump into S7 Search Results filtered
/// to that tag") until Phase 9 (Exact Search) builds the real thing.
struct TaggedDocumentsView: View {

    let tag: Tag

    @Environment(\.modelContext) private var modelContext
    @State private var documents: [Document] = []

    var body: some View {
        List {
            if documents.isEmpty {
                ContentUnavailableView(
                    "No Notes",
                    systemImage: "doc.text",
                    description: Text("No notes are tagged #\(tag.name ?? "").")
                )
            } else {
                ForEach(documents) { document in
                    NavigationLink(document.title ?? "Untitled") {
                        DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
                    }
                }
            }
        }
        .navigationTitle("#\(tag.name ?? "")")
        .noteBytezInlineNavigationTitle()
        .onAppear {
            documents = TagDAL.fetchDocuments(for: tag, in: modelContext)
        }
    }

}
