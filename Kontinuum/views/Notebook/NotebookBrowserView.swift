// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookBrowserView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData

/// S14 — Notebook Browser. List of every notebook in the library with its document count;
/// tapping a notebook drills into its documents (`NotebookDocumentsView`), the same
/// filtered-document-list pattern S13 uses for tags. "+ New" creates a notebook directly,
/// without going through Promote to Notebook.
struct NotebookBrowserView: View {

    var viewModel: NotebookViewModel

    @Environment(\.modelContext) private var modelContext
    @State private var isPresentingCreateNotebook = false

    var body: some View {
        List {
            if viewModel.notebookSummaries.isEmpty {
                ContentUnavailableView(
                    "No Notebooks Yet",
                    systemImage: "books.vertical",
                    description: Text("Promote a journal entry, or create one here.")
                )
            } else {
                ForEach(viewModel.notebookSummaries) { summary in
                    NavigationLink {
                        NotebookDocumentsView(notebook: summary.notebook)
                    } label: {
                        NotebookListRow(name: summary.notebook.name ?? "", documentCount: summary.documentCount)
                    }
                }
            }
        }
        .navigationTitle("Notebooks")
        .noteBytezInlineNavigationTitle()
        .toolbar {
            // iPhone has no dedicated Canvas tab — `CanvasBoard` is library-scoped like
            // Notebooks/Tags, not Notebook-owned, so this is a navigation shortcut, not a data
            // relationship, per UIUX/04-InteractionDesign.md's own note on S16.
            ToolbarItem(placement: .secondaryAction) {
                NavigationLink {
                    CanvasBoardListView(viewModel: CanvasViewModel(libraryId: viewModel.libraryId, modelContext: modelContext))
                } label: {
                    Label("Canvas", systemImage: "square.grid.2x2")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingCreateNotebook = true
                } label: {
                    Label("New Notebook", systemImage: "plus")
                }
            }
        }
        .onAppear {
            viewModel.load()
        }
        .sheet(isPresented: $isPresentingCreateNotebook) {
            CreateNotebookSheet(viewModel: viewModel, isPresented: $isPresentingCreateNotebook)
        }
        .onReceive(NotificationCenter.default.publisher(for: .kontinuumTriggerNewNotebook)) { _ in
            isPresentingCreateNotebook = true
        }
    }

}

private struct CreateNotebookSheet: View {

    var viewModel: NotebookViewModel
    @Binding var isPresented: Bool
    @State private var name: String = ""

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Notebook Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                PrimaryButton(title: "Create") {
                    viewModel.createNotebook(named: name)
                    isPresented = false
                }
                .disabled(!isNameValid)

                SecondaryButton(title: "Cancel") {
                    isPresented = false
                }
            }
            .padding(.top, 24)
            .navigationTitle("New Notebook")
            .noteBytezInlineNavigationTitle()
        }
    }

}

#Preview {
    NavigationStack {
        NotebookBrowserView(viewModel: NotebookViewModel(libraryId: UUID(), modelContext: try! ModelContainer(for: Notebook.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)).mainContext))
    }
}
