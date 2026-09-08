// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

@Observable
final class NotebookViewModel {

    struct NotebookSummary: Identifiable {
        let notebook: Notebook
        let documentCount: Int
        var id: UUID { notebook.notebookId ?? UUID() }
    }

    private(set) var notebookSummaries: [NotebookSummary] = []

    /// Widened from `private` per Phase 7's own precedent (`SearchViewModel`/
    /// `TaskDashboardViewModel`): Phase 9's iPhone Canvas entry point on `NotebookBrowserView`
    /// needs it to construct a `CanvasViewModel` for the same library.
    let libraryId: UUID
    private let modelContext: ModelContext

    init(libraryId: UUID, modelContext: ModelContext) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        self.load()
    }

    func load() {
        notebookSummaries = NotebookDAL.fetchActive(libraryId: libraryId, in: modelContext).map { notebook in
            NotebookSummary(notebook: notebook, documentCount: NotebookDAL.fetchDocuments(for: notebook, in: modelContext).count)
        }
    }

    @discardableResult
    func createNotebook(named name: String) -> Notebook? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }

        let notebook = NotebookDAL.create(name: trimmedName, libraryId: libraryId, in: modelContext)
        load()
        return notebook
    }

    func rename(_ notebook: Notebook, to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        NotebookDAL.rename(notebook, to: trimmedName, in: modelContext)
        load()
    }

    func delete(_ notebook: Notebook) {
        NotebookDAL.softDelete(notebook, in: modelContext)
        load()
    }

    func documents(for notebook: Notebook) -> [Document] {
        NotebookDAL.fetchDocuments(for: notebook, in: modelContext)
    }

    /// Promotes `block` (from `sourceDocument`) into `notebook`, or into a freshly-created
    /// notebook named `newNotebookName` when no existing notebook was chosen.
    @discardableResult
    func promote(block: Block, sourceDocument: Document, into notebook: Notebook?, newNotebookNamed newNotebookName: String?) -> Document? {
        let target: Notebook?
        if let notebook {
            target = notebook
        } else if let newNotebookName, !newNotebookName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            target = createNotebook(named: newNotebookName)
        } else {
            target = nil
        }

        guard let target else { return nil }
        let promoted = NotebookDAL.promote(block: block, sourceDocument: sourceDocument, into: target, in: modelContext)
        load()
        return promoted
    }

}
