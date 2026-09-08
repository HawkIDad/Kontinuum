// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PromoteToNotebookView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData

/// S15 — Promote to Notebook. Choose an existing notebook or name a new one to file a
/// promoted journal block into. A decision the user must complete or cancel before
/// continuing, so it's always a sheet — never auto-commits.
struct PromoteToNotebookView: View {

    var viewModel: NotebookViewModel
    let block: Block
    let sourceDocument: Document
    let onPromoted: (Document) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedNotebook: Notebook?
    @State private var newNotebookName: String = ""

    private var canPromote: Bool {
        selectedNotebook != nil || !newNotebookName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    PromoteSourcePreview(content: block.content ?? "")
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if !viewModel.notebookSummaries.isEmpty {
                    Section("Choose a notebook") {
                        ForEach(viewModel.notebookSummaries) { summary in
                            Button {
                                selectedNotebook = summary.notebook
                                newNotebookName = ""
                            } label: {
                                HStack {
                                    NotebookListRow(name: summary.notebook.name ?? "", documentCount: summary.documentCount)
                                    if selectedNotebook?.notebookId == summary.notebook.notebookId {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(selectedNotebook?.notebookId == summary.notebook.notebookId ? .isSelected : [])
                        }
                    }
                }

                Section("Or create new") {
                    TextField("Notebook Name", text: $newNotebookName)
                        .onChange(of: newNotebookName) { _, newValue in
                            if !newValue.isEmpty { selectedNotebook = nil }
                        }
                }
            }
            .navigationTitle("Promote to Notebook")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Promote") {
                        guard let promoted = viewModel.promote(
                            block: block, sourceDocument: sourceDocument,
                            into: selectedNotebook, newNotebookNamed: newNotebookName
                        ) else { return }
                        onPromoted(promoted)
                        dismiss()
                    }
                    .disabled(!canPromote)
                }
            }
        }
    }

}
