// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphInsightsDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// Answerable graph views (Decision 1) — orphans, stale-but-once-mattered notes, notes with
/// open tasks, hubs, and link clusters. Scan-on-demand over the same `[[link]]` edge set
/// `GraphDAL.directLinks` resolves from, matching `BacklinkDAL`/`SearchDAL`'s established
/// no-persisted-index rationale: this is a read-only "answerable views" screen, not a
/// force-directed graph simulation.
enum GraphInsightsDAL {

    struct HubEntry {
        let document: Document
        let degree: Int
    }

    struct OpenTasksEntry {
        let document: Document
        let openCount: Int
        let nearestDueDate: Date?
    }

    /// Every insight computed together from one link-graph build and one set of fetches —
    /// what `GraphInsightsViewModel.refresh()` actually wants, since a screen showing all five
    /// categories at once has no reason to re-scan the library once per category (Decision 1
    /// is "no *persisted* index," not "no reuse within a single refresh").
    struct Snapshot {
        let orphans: [Document]
        let staleNotes: [Document]
        let notesWithOpenTasks: [OpenTasksEntry]
        let hubs: [HubEntry]
        let clusters: [[Document]]
    }

    static func computeAll(thresholdDays: Int = 90, hubLimit: Int = 10, libraryId: UUID, in context: ModelContext) -> Snapshot {
        let graph = buildLinkGraph(libraryId: libraryId, in: context)
        let tasks = TaskDAL.fetchActive(libraryId: libraryId, in: context)
        return Snapshot(
            orphans: orphans(in: graph),
            staleNotes: staleNotes(thresholdDays: thresholdDays, in: graph, tasks: tasks),
            notesWithOpenTasks: notesWithOpenTasks(in: graph, tasks: tasks),
            hubs: hubs(topN: hubLimit, in: graph),
            clusters: clusters(in: graph)
        )
    }

    /// Documents with neither an incoming nor an outgoing `[[link]]` — an unlinked plain-text
    /// mention doesn't count, since it isn't a link.
    static func orphans(libraryId: UUID, in context: ModelContext) -> [Document] {
        orphans(in: buildLinkGraph(libraryId: libraryId, in: context))
    }

    /// Documents last edited more than `thresholdDays` ago that still have at least one open
    /// task or one backlink — i.e. it once mattered, distinct from a truly abandoned orphan.
    static func staleNotes(thresholdDays: Int = 90, libraryId: UUID, in context: ModelContext) -> [Document] {
        staleNotes(thresholdDays: thresholdDays, in: buildLinkGraph(libraryId: libraryId, in: context), tasks: TaskDAL.fetchActive(libraryId: libraryId, in: context))
    }

    /// Every document with at least one open (`isDone == false`) task, grouped with its open
    /// count and the nearest (soonest) due date among them — `nil` if none of its open tasks
    /// have a due date set.
    static func notesWithOpenTasks(libraryId: UUID, in context: ModelContext) -> [OpenTasksEntry] {
        notesWithOpenTasks(in: buildLinkGraph(libraryId: libraryId, in: context), tasks: TaskDAL.fetchActive(libraryId: libraryId, in: context))
    }

    /// Top-`topN` documents ranked by combined in+out link degree, ties broken by title.
    static func hubs(topN: Int, libraryId: UUID, in context: ModelContext) -> [HubEntry] {
        hubs(topN: topN, in: buildLinkGraph(libraryId: libraryId, in: context))
    }

    /// Connected components of the link graph (undirected — either direction of a `[[link]]`
    /// joins two documents into the same component), via union-find. An orphan is its own
    /// singleton component.
    static func clusters(libraryId: UUID, in context: ModelContext) -> [[Document]] {
        clusters(in: buildLinkGraph(libraryId: libraryId, in: context))
    }

    // MARK: - Graph-scoped implementations (shared by the public per-call API and `computeAll`)

    private static func orphans(in graph: LinkGraph) -> [Document] {
        graph.documents.filter { document in
            guard let id = document.documentId else { return true }
            return (graph.outgoing[id]?.isEmpty ?? true) && (graph.incoming[id]?.isEmpty ?? true)
        }
    }

    private static func staleNotes(thresholdDays: Int, in graph: LinkGraph, tasks: [TaskItem]) -> [Document] {
        let cutoff = Date(timeIntervalSinceNow: -Double(thresholdDays) * 86400)
        let openTaskDocumentIds = Set(tasks.filter { $0.isDone != true }.compactMap { $0.documentId })

        return graph.documents.filter { document in
            guard let updatedOn = document.updatedOn, updatedOn < cutoff, let id = document.documentId else { return false }
            let hasOpenTask = openTaskDocumentIds.contains(id)
            let hasBacklink = !(graph.incoming[id]?.isEmpty ?? true)
            return hasOpenTask || hasBacklink
        }
    }

    private static func notesWithOpenTasks(in graph: LinkGraph, tasks: [TaskItem]) -> [OpenTasksEntry] {
        let documentsById = Dictionary(uniqueKeysWithValues: graph.documents.compactMap { document -> (UUID, Document)? in
            guard let id = document.documentId else { return nil }
            return (id, document)
        })

        var openTasksByDocument: [UUID: [TaskItem]] = [:]
        for task in tasks where task.isDone != true {
            guard let documentId = task.documentId else { continue }
            openTasksByDocument[documentId, default: []].append(task)
        }

        return openTasksByDocument.compactMap { documentId, tasks -> OpenTasksEntry? in
            guard let document = documentsById[documentId] else { return nil }
            let nearestDueDate = tasks.compactMap { $0.dueDate }.min()
            return OpenTasksEntry(document: document, openCount: tasks.count, nearestDueDate: nearestDueDate)
        }
    }

    private static func hubs(topN: Int, in graph: LinkGraph) -> [HubEntry] {
        let entries = graph.documents.compactMap { document -> HubEntry? in
            guard let id = document.documentId else { return nil }
            let degree = (graph.outgoing[id]?.count ?? 0) + (graph.incoming[id]?.count ?? 0)
            return HubEntry(document: document, degree: degree)
        }
        let ranked = entries.sorted { lhs, rhs in
            if lhs.degree != rhs.degree { return lhs.degree > rhs.degree }
            return (lhs.document.title ?? "") < (rhs.document.title ?? "")
        }
        return Array(ranked.prefix(topN))
    }

    private static func clusters(in graph: LinkGraph) -> [[Document]] {
        var disjointSet = DisjointSet<UUID>()
        for document in graph.documents {
            guard let id = document.documentId else { continue }
            disjointSet.makeSet(id)
        }
        for (source, targets) in graph.outgoing {
            for target in targets {
                disjointSet.union(source, target)
            }
        }

        let documentsById = Dictionary(uniqueKeysWithValues: graph.documents.compactMap { document -> (UUID, Document)? in
            guard let id = document.documentId else { return nil }
            return (id, document)
        })

        return disjointSet.components().map { component in
            component.compactMap { documentsById[$0] }
        }
    }

    // MARK: - Link graph

    private struct LinkGraph {
        let documents: [Document]
        /// documentId -> the set of documentIds it links to via `[[title]]`.
        let outgoing: [UUID: Set<UUID>]
        /// documentId -> the set of documentIds that link to it.
        let incoming: [UUID: Set<UUID>]
    }

    /// Builds the whole library's `[[link]]` edge set once — every DAL function above scans
    /// this same structure rather than re-parsing content per call. Title resolution mirrors
    /// `GraphDAL.directLinks`: case-insensitive exact title match, in-library only.
    private static func buildLinkGraph(libraryId: UUID, in context: ModelContext) -> LinkGraph {
        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        let idsByLowercasedTitle = Dictionary(
            documents.compactMap { document -> (String, UUID)? in
                guard let id = document.documentId,
                      let title = document.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                else { return nil }
                return (title.lowercased(), id)
            },
            uniquingKeysWith: { first, _ in first }
        )

        var outgoing: [UUID: Set<UUID>] = [:]
        var incoming: [UUID: Set<UUID>] = [:]
        for document in documents {
            guard let id = document.documentId else { continue }
            for title in WikilinkParser.extractTitles(from: document.content ?? "") {
                guard let targetId = idsByLowercasedTitle[title.lowercased()], targetId != id else { continue }
                outgoing[id, default: []].insert(targetId)
                incoming[targetId, default: []].insert(id)
            }
        }

        return LinkGraph(documents: documents, outgoing: outgoing, incoming: incoming)
    }

}
