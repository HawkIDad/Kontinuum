// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookDocumentsView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData

/// Documents filed into a given notebook — the drill-down destination from S14's notebook
/// list, mirroring `TaggedDocumentsView`'s role for S13.
struct NotebookDocumentsView: View {

    let notebook: Notebook

    @Environment(\.modelContext) private var modelContext
    @State private var documents: [Document] = []
    @State private var isPresentingTemplatePicker = false

    var body: some View {
        List {
            if documents.isEmpty {
                ContentUnavailableView(
                    "No Documents",
                    systemImage: "doc.text",
                    description: Text("No documents are filed in \(notebook.name ?? "this notebook").")
                )
            } else {
                ForEach(documents) { document in
                    NavigationLink(document.title ?? "Untitled") {
                        DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
                    }
                }
            }
        }
        .navigationTitle(notebook.name ?? "Notebook")
        .noteBytezInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingTemplatePicker = true
                } label: {
                    Image(systemName: "plus.square")
                }
                .accessibilityLabel("New Note")
            }
        }
        .onAppear {
            documents = NotebookDAL.fetchDocuments(for: notebook, in: modelContext)
        }
        .sheet(isPresented: $isPresentingTemplatePicker) {
            // Built fresh on each presentation, rather than reading an `.onAppear`-populated
            // `@State` view model — that `@State` could still be nil the first time "+" is
            // tapped right after this screen appears (its `.onAppear` assignment doesn't
            // reliably win the race against a fast tap on this NavigationLink destination),
            // which silently presented a blank sheet instead of the Template Picker.
            if let notebookId = notebook.notebookId, let libraryId = notebook.libraryId {
                TemplatePickerView(scope: .notebook(notebookId), viewModel: TemplateViewModel(libraryId: libraryId, modelContext: modelContext)) { template in
                    createDocument(from: template, notebookId: notebookId, libraryId: libraryId)
                }
            }
        }
    }

    private func createDocument(from template: NoteTemplate?, notebookId: UUID, libraryId: UUID) {
        let document = TemplateDAL.createDocument(from: template, title: "Untitled", libraryId: libraryId, in: modelContext)
        guard let documentId = document.documentId else { return }
        NotebookDAL.attach(documentId: documentId, notebookId: notebookId, libraryId: libraryId, in: modelContext)
        documents = NotebookDAL.fetchDocuments(for: notebook, in: modelContext)
    }

}
