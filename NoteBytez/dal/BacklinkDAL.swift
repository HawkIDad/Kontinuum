// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BacklinkDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// Computes backlinks on demand by scanning document content — there's no persisted/synced
/// link index in MVP. Fine at this scale, and avoids maintaining an index's invalidation
/// rules prematurely. Block-level backlinks are explicitly a V1 feature, not MVP, so matches
/// are document-scoped; a block is only consulted to produce a short snippet.
enum BacklinkDAL {

    static func findBacklinks(to targetTitle: String, excluding documentId: UUID, libraryId: UUID, in context: ModelContext) -> [BacklinkMatch] {
        let candidates = DocumentDAL.fetchActive(libraryId: libraryId, in: context).filter { $0.documentId != documentId }

        var matches: [BacklinkMatch] = []
        for document in candidates {
            let titles = WikilinkParser.extractTitles(from: document.content ?? "")
            guard titles.contains(where: { $0.caseInsensitiveCompare(targetTitle) == .orderedSame }) else { continue }
            matches.append(BacklinkMatch(sourceDocument: document, snippet: wikilinkSnippet(for: targetTitle, in: document, context: context)))
        }
        return matches
    }

    static func findUnlinkedMentions(to targetTitle: String, excludingDocumentIds: Set<UUID>, libraryId: UUID, in context: ModelContext) -> [BacklinkMatch] {
        let trimmedTitle = targetTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return [] }

        let candidates = DocumentDAL.fetchActive(libraryId: libraryId, in: context).filter { document in
            guard let documentId = document.documentId else { return false }
            return !excludingDocumentIds.contains(documentId)
        }

        var matches: [BacklinkMatch] = []
        for document in candidates {
            guard let content = document.content, content.localizedCaseInsensitiveContains(trimmedTitle) else { continue }
            matches.append(BacklinkMatch(sourceDocument: document, snippet: plainTextSnippet(for: trimmedTitle, in: document, context: context)))
        }
        return matches
    }

    private static func wikilinkSnippet(for title: String, in document: Document, context: ModelContext) -> String {
        guard let documentId = document.documentId else { return truncate(document.content ?? "") }
        let blocks = BlockDAL.fetchActive(documentId: documentId, in: context)
        let matchingBlock = blocks.first { block in
            WikilinkParser.extractTitles(from: block.content ?? "").contains { $0.caseInsensitiveCompare(title) == .orderedSame }
        }
        return truncate(matchingBlock?.content ?? document.content ?? "")
    }

    private static func plainTextSnippet(for text: String, in document: Document, context: ModelContext) -> String {
        guard let documentId = document.documentId else { return truncate(document.content ?? "") }
        let blocks = BlockDAL.fetchActive(documentId: documentId, in: context)
        let matchingBlock = blocks.first { ($0.content ?? "").localizedCaseInsensitiveContains(text) }
        return truncate(matchingBlock?.content ?? document.content ?? "")
    }

    private static func truncate(_ text: String, limit: Int = 140) -> String {
        let collapsed = text.replacingOccurrences(of: "\n", with: " ")
        guard collapsed.count > limit else { return collapsed }
        return String(collapsed.prefix(limit)) + "…"
    }

}
