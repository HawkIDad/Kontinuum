// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentListView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// All Notes — the reachable entry point into S4 for browsing/creating notes directly,
/// independent of the S3 journal. Mac/iPad sidebar only, per UIUX/04-InteractionDesign.md's
/// navigation shell.
struct DocumentListView: View {

    @Environment(\.modelContext) private var modelContext
    let libraryId: UUID

    @State private var documents: [Document] = []
    @State private var isPresentingTemplatePicker = false

    var body: some View {
        List {
            if documents.isEmpty {
                ContentUnavailableView(
                    "No Notes Yet",
                    systemImage: "doc.text",
                    description: Text("Tap + to create your first note.")
                )
            } else {
                ForEach(documents) { document in
                    NavigationLink(document.title ?? "Untitled") {
                        DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
                    }
                }
            }
        }
        .navigationTitle("All Notes")
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
            reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: .noteBytezNewNote)) { _ in
            isPresentingTemplatePicker = true
        }
        .sheet(isPresented: $isPresentingTemplatePicker) {
            // Built fresh on each presentation rather than an `.onAppear`-populated `@State`
            // view model — see `NotebookDocumentsView`'s identical fix for why that race can
            // silently present a blank sheet instead of the Template Picker.
            TemplatePickerView(scope: .library, viewModel: TemplateViewModel(libraryId: libraryId, modelContext: modelContext)) { template in
                createDocument(from: template)
            }
        }
    }

    private func reload() {
        documents = DocumentDAL.fetchActive(libraryId: libraryId, in: modelContext)
    }

    private func createDocument(from template: NoteTemplate?) {
        _ = TemplateDAL.createDocument(from: template, title: "Untitled", libraryId: libraryId, in: modelContext)
        reload()
    }

}
