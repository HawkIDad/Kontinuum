// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

enum NotebookDAL {

    static func create(name: String, libraryId: UUID, in context: ModelContext) -> Notebook {
        let notebook = Notebook(name: name, libraryId: libraryId)
        context.insert(notebook)
        SyncEngine.shared.recordChanged(notebook, in: context)
        return notebook
    }

    static func fetchActive(libraryId: UUID, in context: ModelContext) -> [Notebook] {
        let predicate = #Predicate<Notebook> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<Notebook>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Exact-name match (unlike `TagDAL.findOrCreate`, no case-folding) — Notebook membership
    /// round-trips through import by exact name, per NoteBytez-ReleaseFeatures.md's Decisions
    /// Log.
    static func findOrCreate(name: String, libraryId: UUID, in context: ModelContext) -> Notebook {
        if let existing = fetchActive(libraryId: libraryId, in: context).first(where: { $0.name == name }) {
            return existing
        }
        return create(name: name, libraryId: libraryId, in: context)
    }

    static func rename(_ notebook: Notebook, to name: String, in context: ModelContext) {
        notebook.name = name
        notebook.updatedOn = Date()
        SyncEngine.shared.recordChanged(notebook, in: context)
    }

    static func softDelete(_ notebook: Notebook, in context: ModelContext) {
        notebook.isActive = false
        notebook.updatedOn = Date()
        SyncEngine.shared.recordChanged(notebook, in: context)
    }

    /// Upserts the join row — reactivates a previously-detached one rather than duplicating it.
    @discardableResult
    static func attach(documentId: UUID, notebookId: UUID, libraryId: UUID, in context: ModelContext) -> DocumentNotebook {
        let predicate = #Predicate<DocumentNotebook> { $0.documentId == documentId && $0.notebookId == notebookId }
        if let existing = (try? context.fetch(FetchDescriptor<DocumentNotebook>(predicate: predicate)))?.first {
            if existing.isActive != true {
                existing.isActive = true
                existing.updatedOn = Date()
                SyncEngine.shared.recordChanged(existing, in: context)
            }
            return existing
        }
        let join = DocumentNotebook(documentId: documentId, notebookId: notebookId, libraryId: libraryId)
        context.insert(join)
        SyncEngine.shared.recordChanged(join, in: context)
        return join
    }

    static func detach(documentId: UUID, notebookId: UUID, in context: ModelContext) {
        let predicate = #Predicate<DocumentNotebook> { $0.documentId == documentId && $0.notebookId == notebookId && $0.isActive == true }
        guard let join = (try? context.fetch(FetchDescriptor<DocumentNotebook>(predicate: predicate)))?.first else { return }
        join.isActive = false
        join.updatedOn = Date()
        SyncEngine.shared.recordChanged(join, in: context)
    }

    static func fetchNotebooks(for documentId: UUID, in context: ModelContext) -> [Notebook] {
        let predicate = #Predicate<DocumentNotebook> { $0.documentId == documentId && $0.isActive == true }
        let joins = (try? context.fetch(FetchDescriptor<DocumentNotebook>(predicate: predicate))) ?? []
        guard let libraryId = joins.first?.libraryId else { return [] }

        let notebookIds = Set(joins.compactMap { $0.notebookId })
        return fetchActive(libraryId: libraryId, in: context).filter { notebook in
            guard let notebookId = notebook.notebookId else { return false }
            return notebookIds.contains(notebookId)
        }
    }

    static func fetchDocuments(for notebook: Notebook, in context: ModelContext) -> [Document] {
        guard let notebookId = notebook.notebookId, let libraryId = notebook.libraryId else { return [] }

        let predicate = #Predicate<DocumentNotebook> { $0.notebookId == notebookId && $0.isActive == true }
        let joins = (try? context.fetch(FetchDescriptor<DocumentNotebook>(predicate: predicate))) ?? []
        let documentIds = Set(joins.compactMap { $0.documentId })

        return DocumentDAL.fetchActive(libraryId: libraryId, in: context).filter { document in
            guard let documentId = document.documentId else { return false }
            return documentIds.contains(documentId)
        }
    }

    /// Turns a Journal `Block` into a new `Document` filed into `notebook`, and links the two
    /// in both directions with `[[wikilink]]`s — the source entry is never modified beyond
    /// appending that link, so promoting always reads as copy-and-link, never move. The new
    /// document also records `promotedFromDocumentId`/`promotedFromBlockId`, a block-aware
    /// provenance link independent of the wikilink text.
    @discardableResult
    static func promote(block: Block, sourceDocument: Document, into notebook: Notebook, in context: ModelContext) -> Document? {
        guard let libraryId = sourceDocument.libraryId,
              let notebookId = notebook.notebookId,
              let blockContent = block.content else { return nil }

        let sourceTitle = sourceDocument.title ?? ""
        let newTitle = promotedTitle(from: blockContent)
        let newContent = sourceTitle.isEmpty ? blockContent : "\(blockContent)\n\n[[\(sourceTitle)]]"

        let newDocument = DocumentDAL.create(title: newTitle, content: newContent, libraryId: libraryId, in: context)
        guard let newDocumentId = newDocument.documentId else { return newDocument }

        newDocument.promotedFromDocumentId = sourceDocument.documentId
        newDocument.promotedFromBlockId = block.blockId
        SyncEngine.shared.recordChanged(newDocument, in: context)

        attach(documentId: newDocumentId, notebookId: notebookId, libraryId: libraryId, in: context)

        appendBackLink(to: sourceDocument, block: block, newTitle: newTitle, in: context)

        return newDocument
    }

    /// Splices `[[newTitle]]` onto the promoted block by its position among the source
    /// document's current blocks (`block.sortOrder`, the same identity `BlockDAL.syncBlocks`
    /// assigns), not a raw string search — a substring search can splice into the wrong block
    /// when two blocks share identical text. Skips the splice (new document is still created
    /// and still linked via `promotedFromBlockId`) if the source has been edited since the
    /// block was read and no longer matches at that position.
    private static func appendBackLink(to sourceDocument: Document, block: Block, newTitle: String, in context: ModelContext) {
        guard let sourceContent = sourceDocument.content,
              let blockContent = block.content,
              let sortOrder = block.sortOrder else { return }

        var chunks = MarkdownBlockSplitter.split(sourceContent)
        guard chunks.indices.contains(sortOrder), chunks[sortOrder] == blockContent else { return }

        chunks[sortOrder] = "\(blockContent) [[\(newTitle)]]"
        DocumentDAL.updateContent(sourceDocument, content: MarkdownBlockSplitter.join(chunks), in: context)
    }

    /// First line of the block, with a leading list/checkbox/heading marker stripped, as the
    /// promoted note's title — matches how outliner-style "promote block to page" tools name
    /// the new page from the block's own text rather than prompting for one.
    static func promotedTitle(from blockContent: String) -> String {
        guard let firstLine = blockContent.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true).first else {
            return "Untitled"
        }

        var text = String(firstLine)
        if let checkboxRange = text.range(of: #"^-\s*\[[ xX]\]\s*"#, options: .regularExpression) {
            text.removeSubrange(checkboxRange)
        } else if let bulletRange = text.range(of: #"^[-*]\s+"#, options: .regularExpression) {
            text.removeSubrange(bulletRange)
        } else if let headingRange = text.range(of: #"^#+\s+"#, options: .regularExpression) {
            text.removeSubrange(headingRange)
        }

        text = text.trimmingCharacters(in: .whitespaces)
        if text.count > 80 {
            text = String(text.prefix(80))
        }
        return text.isEmpty ? "Untitled" : text
    }

}
