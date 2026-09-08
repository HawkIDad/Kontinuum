// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// Commits an `ImportScanner` scan: one `Document` per file (which internally splits into
/// `Block`s, per `DocumentDAL.create`), then indexes `Tag`s and `TaskItem`s from that same
/// content. Backlinks need no separate step — `BacklinkDAL` resolves `[[wikilink]]`s by
/// scanning document content on demand, and imported content already carries that syntax
/// verbatim from the source files.
enum ImportDAL {

    @discardableResult
    static func importFiles(_ summaries: [ImportFileSummary], libraryId: UUID, in context: ModelContext) -> Int {
        for summary in summaries {
            let document = DocumentDAL.create(title: summary.title, content: summary.content, libraryId: libraryId, in: context)
            guard let documentId = document.documentId else { continue }
            TagDAL.syncTags(for: documentId, content: summary.content, libraryId: libraryId, in: context)
            TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)
            PropertyDAL.syncProperties(for: documentId, content: summary.content, libraryId: libraryId, in: context)

            for notebookName in summary.notebookNames {
                let notebook = NotebookDAL.findOrCreate(name: notebookName, libraryId: libraryId, in: context)
                guard let notebookId = notebook.notebookId else { continue }
                NotebookDAL.attach(documentId: documentId, notebookId: notebookId, libraryId: libraryId, in: context)
            }
        }
        return summaries.count
    }

}
