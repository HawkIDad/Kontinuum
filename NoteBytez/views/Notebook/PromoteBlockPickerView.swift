// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PromoteBlockPickerView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// Entry point for Promote to Notebook from a journal entry: pick which block to promote,
/// then hands off to `PromoteToNotebookView` (S15). A separate picker step rather than a
/// long-press directly on the rendered block — this environment's ScrollView tap-gesture
/// delivery is already documented as unreliable for wikilinks/task checkboxes, so a plain
/// list row is the more dependable trigger for the same action.
struct PromoteBlockPickerView: View {

    let sourceDocument: Document
    let notebookViewModel: NotebookViewModel
    let onPromoted: (Document) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var blocks: [Block] = []

    var body: some View {
        NavigationStack {
            List {
                if blocks.isEmpty {
                    ContentUnavailableView(
                        "Nothing to Promote",
                        systemImage: "books.vertical",
                        description: Text("Write something in today's journal first.")
                    )
                } else {
                    ForEach(blocks) { block in
                        NavigationLink {
                            PromoteToNotebookView(
                                viewModel: notebookViewModel,
                                block: block,
                                sourceDocument: sourceDocument,
                                onPromoted: { document in
                                    onPromoted(document)
                                    dismiss()
                                }
                            )
                        } label: {
                            Text(block.content ?? "")
                                .lineLimit(2)
                        }
                    }
                }
            }
            .navigationTitle("Promote a Block")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let documentId = sourceDocument.documentId {
                    blocks = BlockDAL.fetchActive(documentId: documentId, in: modelContext)
                        .filter { !($0.content ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                }
            }
        }
    }

}
