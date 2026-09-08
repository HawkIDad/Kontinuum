// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// Commits a `MigrationScanner` scan — the Migration Assistant's counterpart to `ImportDAL`.
/// Ordinary pages reuse `ImportDAL.importFiles` outright (it already handles tags/tasks/
/// properties/notebooks generically, format-agnostic); journal pages and canvas boards each need
/// their own small commit path `ImportDAL` has no equivalent of.
enum MigrationDAL {

    @discardableResult
    static func commit(_ result: MigrationScanResult, libraryId: UUID, in context: ModelContext) -> Int {
        ImportDAL.importFiles(result.pages, libraryId: libraryId, in: context)
        commitJournalPages(result.journalPages, libraryId: libraryId, in: context)
        commitCanvasFiles(result.canvasFiles, libraryId: libraryId, in: context)
        return result.noteCount
    }

    /// Routes through `JournalDAL.fetchOrCreate` rather than `DocumentDAL.create` — a journal
    /// page must land as *the* day's journal entry (`isJournalEntry`/`journalDate`), not an
    /// ordinary note that merely happens to be titled with a date.
    private static func commitJournalPages(_ journalPages: [(summary: ImportFileSummary, date: Date)], libraryId: UUID, in context: ModelContext) {
        for (summary, date) in journalPages {
            let document = JournalDAL.fetchOrCreate(for: date, libraryId: libraryId, in: context)
            guard let documentId = document.documentId else { continue }
            DocumentDAL.updateContent(document, content: summary.content, in: context)
            TagDAL.syncTags(for: documentId, content: summary.content, libraryId: libraryId, in: context)
            TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)
        }
    }

    /// Run *after* `ImportDAL.importFiles` above (not just listed after it) — `CanvasDAL.
    /// importJSONCanvas`'s `file`-node resolution matches against the library's *existing*
    /// Documents, so the pages a `.canvas` board references must already exist.
    private static func commitCanvasFiles(_ canvasFiles: [MigrationCanvasFileSummary], libraryId: UUID, in context: ModelContext) {
        for canvasFile in canvasFiles {
            _ = CanvasDAL.importJSONCanvas(canvasFile.json, boardName: canvasFile.boardName, libraryId: libraryId, in: context)
        }
    }

}
