// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SearchDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// Computes search results on demand by scanning active documents — there's no persisted FTS
/// index in MVP, matching `BacklinkDAL`'s established rationale: fine at this scale, and avoids
/// maintaining an index's invalidation rules prematurely.
enum SearchDAL {

    struct SearchResult: Identifiable {
        let document: Document
        let snippet: String
        var id: UUID { document.documentId ?? UUID() }
    }

    /// Matches title or content (case-insensitive substring), ranked with title hits above
    /// content-only hits, and more occurrences ranked above fewer.
    static func searchContent(query: String, libraryId: UUID, in context: ModelContext) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let candidates = DocumentDAL.fetchActive(libraryId: libraryId, in: context).filter { document in
            (document.title ?? "").localizedCaseInsensitiveContains(trimmed) ||
            (document.content ?? "").localizedCaseInsensitiveContains(trimmed)
        }

        return candidates
            .sorted { relevance($0, query: trimmed) > relevance($1, query: trimmed) }
            .map { SearchResult(document: $0, snippet: snippet(for: $0.content ?? "", query: trimmed)) }
    }

    /// "Path" scope: in a flat, no-folders library a note's title is the closest thing it has
    /// to a path, so this is a title-only search — see NoteBytez-ReleaseFeatures.md's
    /// Decisions Log.
    static func searchByTitle(query: String, libraryId: UUID, in context: ModelContext) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        return DocumentDAL.fetchActive(libraryId: libraryId, in: context)
            .filter { ($0.title ?? "").localizedCaseInsensitiveContains(trimmed) }
            .map { SearchResult(document: $0, snippet: $0.title ?? "") }
    }

    /// Reuses Phase 5's tag index (`TagDAL`) rather than re-deriving anything — a document
    /// tagged more than once still appears once, credited to its first matching tag.
    static func searchByTag(query: String, libraryId: UUID, in context: ModelContext) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let matchingTags = TagDAL.fetchActive(libraryId: libraryId, in: context)
            .filter { ($0.name ?? "").localizedCaseInsensitiveContains(trimmed) }

        var seenDocumentIds: Set<UUID> = []
        var results: [SearchResult] = []
        for tag in matchingTags {
            for document in TagDAL.fetchDocuments(for: tag, in: context) {
                guard let documentId = document.documentId, seenDocumentIds.insert(documentId).inserted else { continue }
                results.append(SearchResult(document: document, snippet: "#\(tag.name ?? "")"))
            }
        }
        return results
    }

    /// Boolean query search (Phase 5) — AND/OR/NOT, exact phrase, `#tag`, and `/regex/` terms
    /// evaluated across content, tags, and title/path in one pass, per
    /// NoteBytez-ReleaseFeatures.md's Version 1 "Advanced search". A `#tag` term always checks
    /// the document's tags; every other term type is scoped by `scope` the same way
    /// `searchContent`/`searchByTitle` already split content-or-title from title-only — `.tag`
    /// scope isn't meaningful to the evaluator itself (there's no bare-term-as-tag mode; use
    /// explicit `#tag` syntax for that), so it falls back to `.content`.
    static func searchAdvanced(query: String, scope: SearchViewModel.Scope, libraryId: UUID, in context: ModelContext) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // A malformed boolean expression (unbalanced quote/paren) falls back to a plain literal
        // match on the whole string, rather than showing no results for what was probably just
        // a typo, not a deliberate boolean query.
        let node = AdvancedSearchParser.parse(trimmed) ?? .text(trimmed)
        let defaultScope: AdvancedSearchParser.DefaultScope = (scope == .path) ? .path : .content

        var results: [SearchResult] = []
        for document in DocumentDAL.fetchActive(libraryId: libraryId, in: context) {
            guard let documentId = document.documentId else { continue }
            let tags = Set(TagDAL.fetchTags(for: documentId, in: context).compactMap { $0.name })
            let title = document.title ?? ""
            let content = document.content ?? ""

            guard AdvancedSearchParser.matches(node, title: title, content: content, tags: tags, defaultScope: defaultScope) else { continue }
            results.append(SearchResult(document: document, snippet: advancedSnippet(for: node, content: content)))
        }
        return results
    }

    private static func advancedSnippet(for node: AdvancedSearchParser.Node, content: String) -> String {
        if let text = firstTextLeaf(node) {
            return snippet(for: content, query: text)
        }
        let tags = collectTags(node)
        guard !tags.isEmpty else { return truncate(content, limit: 140) }
        return tags.map { "#\($0)" }.joined(separator: " ")
    }

    /// A `.regex` leaf is deliberately excluded — its raw pattern isn't a literal substring to
    /// center a snippet on.
    private static func firstTextLeaf(_ node: AdvancedSearchParser.Node) -> String? {
        switch node {
        case .and(let lhs, let rhs), .or(let lhs, let rhs):
            return firstTextLeaf(lhs) ?? firstTextLeaf(rhs)
        case .not(let operand):
            return firstTextLeaf(operand)
        case .text(let text):
            return text
        case .tag, .regex:
            return nil
        }
    }

    private static func collectTags(_ node: AdvancedSearchParser.Node) -> [String] {
        switch node {
        case .and(let lhs, let rhs), .or(let lhs, let rhs):
            return collectTags(lhs) + collectTags(rhs)
        case .not(let operand):
            return collectTags(operand)
        case .tag(let name):
            return [name]
        case .text, .regex:
            return []
        }
    }

    /// Reuses Phase 2's Property index (`PropertyDAL`) — matches a property's value
    /// (case-insensitive substring), mirroring `searchByTag`'s shape. A document with more
    /// than one matching property still appears once, credited to its first match.
    static func searchByProperty(query: String, libraryId: UUID, in context: ModelContext) -> [SearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        var seenDocumentIds: Set<UUID> = []
        var results: [SearchResult] = []
        for document in documents {
            guard let documentId = document.documentId else { continue }
            let match = PropertyDAL.fetchProperties(for: documentId, in: context)
                .first { $0.value.localizedCaseInsensitiveContains(trimmed) }
            guard let match, seenDocumentIds.insert(documentId).inserted else { continue }
            results.append(SearchResult(document: document, snippet: "\(match.property.name ?? ""): \(match.value)"))
        }
        return results
    }

    /// S6's fuzzy note-title matcher — reuses the same subsequence-fuzzy-match heuristic as
    /// wikilink autocomplete rather than a second implementation.
    static func quickSwitcherMatches(query: String, libraryId: UUID, in context: ModelContext, limit: Int = 20) -> [Document] {
        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return Array(documents.prefix(limit)) }

        return Array(documents.filter { WikilinkParser.fuzzyMatches($0.title ?? "", query: trimmed) }.prefix(limit))
    }

    private static func relevance(_ document: Document, query: String) -> Int {
        var score = 0
        if (document.title ?? "").localizedCaseInsensitiveContains(query) { score += 1000 }
        score += occurrenceCount(of: query, in: document.content ?? "")
        return score
    }

    private static func occurrenceCount(of query: String, in text: String) -> Int {
        guard !query.isEmpty else { return 0 }
        return text.lowercased().components(separatedBy: query.lowercased()).count - 1
    }

    private static func snippet(for content: String, query: String, contextLength: Int = 40, limit: Int = 140) -> String {
        guard let range = content.range(of: query, options: .caseInsensitive) else {
            return truncate(content, limit: limit)
        }

        let start = content.index(range.lowerBound, offsetBy: -contextLength, limitedBy: content.startIndex) ?? content.startIndex
        let end = content.index(range.upperBound, offsetBy: contextLength, limitedBy: content.endIndex) ?? content.endIndex
        let excerpt = content[start..<end].replacingOccurrences(of: "\n", with: " ")

        let prefix = start > content.startIndex ? "…" : ""
        let suffix = end < content.endIndex ? "…" : ""
        return prefix + excerpt + suffix
    }

    private static func truncate(_ text: String, limit: Int) -> String {
        let collapsed = text.replacingOccurrences(of: "\n", with: " ")
        guard collapsed.count > limit else { return collapsed }
        return String(collapsed.prefix(limit)) + "…"
    }

}
