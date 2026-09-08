// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BlockReferenceDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// Resolves `((anchor))` block references and computes block-level backlinks — the V1
/// extension of MVP's document-level `BacklinkDAL` down to block granularity. Computed on
/// demand by scanning content, same "no persisted index" rationale as `BacklinkDAL`/`SearchDAL`.
enum BlockReferenceDAL {

    struct ResolvedBlockReference {
        let block: Block
        let document: Document
    }

    /// Resolves `anchor` to a specific `Block` and its owning `Document`, regardless of which
    /// document contains it. An anchor is only unique *within* a document (`BlockDAL.syncBlocks`
    /// dedupes there, not library-wide), so two blocks in different documents could in
    /// principle share one — the same inherent limitation Obsidian's own hand-typed block IDs
    /// have. Resolution prefers a match in `preferringDocumentId` (the document currently being
    /// viewed/edited) when one exists; otherwise falls back to the library-wide first match,
    /// sorted by document title then block position, for determinism.
    static func resolve(anchor: String, preferringDocumentId: UUID?, libraryId: UUID, in context: ModelContext) -> ResolvedBlockReference? {
        let matches = BlockDAL.fetchActive(libraryId: libraryId, in: context).filter { $0.anchor == anchor }
        guard !matches.isEmpty else { return nil }

        let documentsById = Dictionary(uniqueKeysWithValues: DocumentDAL.fetchActive(libraryId: libraryId, in: context).compactMap { document -> (UUID, Document)? in
            guard let documentId = document.documentId else { return nil }
            return (documentId, document)
        })

        if let preferringDocumentId,
           let preferred = matches.first(where: { $0.documentId == preferringDocumentId }),
           let document = documentsById[preferringDocumentId] {
            return ResolvedBlockReference(block: preferred, document: document)
        }

        let sorted = matches.sorted { lhs, rhs in
            let lhsTitle = lhs.documentId.flatMap { documentsById[$0]?.title } ?? ""
            let rhsTitle = rhs.documentId.flatMap { documentsById[$0]?.title } ?? ""
            if lhsTitle != rhsTitle { return lhsTitle < rhsTitle }
            return (lhs.sortOrder ?? 0) < (rhs.sortOrder ?? 0)
        }
        guard let first = sorted.first, let documentId = first.documentId, let document = documentsById[documentId] else { return nil }
        return ResolvedBlockReference(block: first, document: document)
    }

    /// `((` autocomplete matches — fuzzy match across every active block's anchor or content,
    /// mirroring `WikilinkParser.fuzzyMatches`'s use for wikilink/tag autocomplete rather than
    /// a second fuzzy-match implementation.
    static func autocompleteMatches(query: String, libraryId: UUID, in context: ModelContext, limit: Int = 8) -> [Block] {
        let blocks = BlockDAL.fetchActive(libraryId: libraryId, in: context)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Array(blocks.prefix(limit)) }

        return Array(blocks.filter { block in
            WikilinkParser.fuzzyMatches(block.anchor ?? "", query: trimmed)
                || WikilinkParser.fuzzyMatches(block.content ?? "", query: trimmed)
                || WikilinkParser.fuzzyMatches(block.headingPath ?? "", query: trimmed)
        }.prefix(limit))
    }

    /// Documents (other than `documentId`) whose content contains a `((anchor))` reference to
    /// the block anchored `anchor` — block-level backlinks, extending
    /// `BacklinkDAL.findBacklinks`'s document-level shape down to block granularity.
    static func findBlockBacklinks(to anchor: String, excluding documentId: UUID, libraryId: UUID, in context: ModelContext) -> [BacklinkMatch] {
        let candidates = DocumentDAL.fetchActive(libraryId: libraryId, in: context).filter { $0.documentId != documentId }

        var matches: [BacklinkMatch] = []
        for document in candidates {
            let anchors = BlockReferenceParser.extractAnchors(from: document.content ?? "")
            guard anchors.contains(anchor) else { continue }
            matches.append(BacklinkMatch(sourceDocument: document, snippet: snippet(for: anchor, in: document, context: context)))
        }
        return matches
    }

    private static func snippet(for anchor: String, in document: Document, context: ModelContext) -> String {
        guard let documentId = document.documentId else { return truncate(document.content ?? "") }
        let blocks = BlockDAL.fetchActive(documentId: documentId, in: context)
        let matchingBlock = blocks.first { BlockReferenceParser.extractAnchors(from: $0.content ?? "").contains(anchor) }
        return truncate(matchingBlock?.content ?? document.content ?? "")
    }

    private static func truncate(_ text: String, limit: Int = 140) -> String {
        let collapsed = text.replacingOccurrences(of: "\n", with: " ")
        guard collapsed.count > limit else { return collapsed }
        return String(collapsed.prefix(limit)) + "…"
    }

}
