// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

enum DocumentDAL {

    static func create(title: String, content: String, libraryId: UUID, in context: ModelContext) -> Document {
        let document = Document(title: title, content: content, libraryId: libraryId)
        context.insert(document)
        SyncEngine.shared.recordChanged(document, in: context)
        if let documentId = document.documentId {
            BlockDAL.syncBlocks(for: documentId, markdown: content, in: context)
        }
        return document
    }

    static func fetchActive(libraryId: UUID, in context: ModelContext) -> [Document] {
        let predicate = #Predicate<Document> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<Document>(predicate: predicate, sortBy: [SortDescriptor(\.updatedOn, order: .reverse)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func updateContent(_ document: Document, content: String, in context: ModelContext) {
        document.content = content
        document.updatedOn = Date()
        SyncEngine.shared.recordChanged(document, in: context)
        if let documentId = document.documentId {
            BlockDAL.syncBlocks(for: documentId, markdown: content, in: context)
        }
    }

    /// Appends `[[title]]` as a new trailing paragraph — used by Canvas's connector-creates-link
    /// flow (Workstream C, Decision 9(a)) where there's no active editing session/cursor to
    /// splice into, unlike `WikilinkParser.applying`'s in-progress-typing replacement.
    static func appendWikilink(to document: Document, title: String, in context: ModelContext) {
        let existing = document.content ?? ""
        let separator = existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n\n"
        updateContent(document, content: existing + separator + "[[\(title)]]", in: context)
    }

    /// Renames the document and rewrites every `[[oldTitle]]` wikilink pointing to it, in
    /// every other active document in the library, to `[[newTitle]]` — so links never break
    /// on rename.
    static func updateTitle(_ document: Document, title: String, in context: ModelContext) {
        let oldTitle = document.title ?? ""
        document.title = title
        document.updatedOn = Date()
        SyncEngine.shared.recordChanged(document, in: context)

        guard oldTitle != title,
              !oldTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let libraryId = document.libraryId,
              let documentId = document.documentId else { return }

        let otherDocuments = fetchActive(libraryId: libraryId, in: context).filter { $0.documentId != documentId }
        for other in otherDocuments {
            guard let content = other.content else { continue }
            let renamed = WikilinkParser.renamingWikilinks(from: oldTitle, to: title, in: content)
            guard renamed != content else { continue }
            updateContent(other, content: renamed, in: context)
        }
    }

    static func softDelete(_ document: Document, in context: ModelContext) {
        document.isActive = false
        document.updatedOn = Date()
        SyncEngine.shared.recordChanged(document, in: context)
        if let documentId = document.documentId {
            for block in BlockDAL.fetchActive(documentId: documentId, in: context) {
                block.isActive = false
                block.updatedOn = Date()
                SyncEngine.shared.recordChanged(block, in: context)
            }
        }
    }

}
