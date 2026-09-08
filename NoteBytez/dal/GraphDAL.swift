// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// MVP graph scope is one hop: the current note plus its direct links, no clustering/forces/
/// filters (per Decisions Log). Reuses `WikilinkParser` for outgoing links and Phase 4's
/// `BacklinkDAL` for incoming links rather than maintaining a separate graph index — that's
/// what keeps S8's edges from ever drifting out of sync with S5's Backlinks Pane.
enum GraphDAL {

    static func directLinks(for document: Document, libraryId: UUID, in context: ModelContext) -> [Document] {
        guard let documentId = document.documentId else { return [] }

        let activeDocuments = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        let outgoingTitles = Set(WikilinkParser.extractTitles(from: document.content ?? "").map { $0.lowercased() })
        let outgoing = activeDocuments.filter { candidate in
            candidate.documentId != documentId && outgoingTitles.contains((candidate.title ?? "").lowercased())
        }

        let incoming: [Document]
        if let title = document.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            incoming = BacklinkDAL.findBacklinks(to: title, excluding: documentId, libraryId: libraryId, in: context).map { $0.sourceDocument }
        } else {
            incoming = []
        }

        var seenIds = Set<UUID>()
        var result: [Document] = []
        for candidate in outgoing + incoming {
            guard let candidateId = candidate.documentId, !seenIds.contains(candidateId) else { continue }
            seenIds.insert(candidateId)
            result.append(candidate)
        }
        return result.sorted { ($0.title ?? "") < ($1.title ?? "") }
    }

    /// Generalizes `directLinks` to N hops via breadth-first search, for S8's force-graph mode
    /// (Decision 4/5) — each result carries its hop distance from `document` for styling
    /// (e.g. dimming farther nodes). `depth: 1` yields exactly `directLinks`' node set (hop 1
    /// for every member); `depth: 2` additionally includes each of those nodes' own direct
    /// links, deduped against everything already found. `document` itself is never included.
    static func neighborhood(of document: Document, depth: Int, libraryId: UUID, in context: ModelContext) -> [(document: Document, hopDistance: Int)] {
        guard let rootId = document.documentId, depth >= 1 else { return [] }

        var hopByDocumentId: [UUID: Int] = [rootId: 0]
        var documentsById: [UUID: Document] = [:]
        var frontier: [Document] = [document]

        for hop in 1...depth {
            var nextFrontier: [Document] = []
            for current in frontier {
                for neighbor in directLinks(for: current, libraryId: libraryId, in: context) {
                    guard let neighborId = neighbor.documentId, hopByDocumentId[neighborId] == nil else { continue }
                    hopByDocumentId[neighborId] = hop
                    documentsById[neighborId] = neighbor
                    nextFrontier.append(neighbor)
                }
            }
            frontier = nextFrontier
            if frontier.isEmpty { break }
        }

        return documentsById.compactMap { id, document -> (document: Document, hopDistance: Int)? in
            guard let hop = hopByDocumentId[id] else { return nil }
            return (document: document, hopDistance: hop)
        }.sorted { lhs, rhs in
            if lhs.hopDistance != rhs.hopDistance { return lhs.hopDistance < rhs.hopDistance }
            return (lhs.document.title ?? "") < (rhs.document.title ?? "")
        }
    }

}
