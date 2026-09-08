// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphFilter.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// S8 force-graph mode's filter state (Decision 5): depth, node-type toggles, and a
/// tag-scope. View state, not persisted, with one exception — a "graph filter preset" is
/// saveable through `SavedViewDAL` (`Codable` so it round-trips through `SavedView.definitionJSON`
/// the same way `SavedSearchDefinition` already does).
nonisolated struct GraphFilter: Codable, Equatable {

    var depth: Int = 1
    var showPlainNotes: Bool = true
    var showNotesWithOpenTasks: Bool = true
    var showOrphans: Bool = true
    var tagScope: String? = nil

    /// Filters a `GraphDAL.neighborhood` result down to the node types currently toggled on. A
    /// node can match more than one class (e.g. it has open tasks and also has no links of its
    /// own elsewhere in the library) — it's included if it matches any enabled class.
    func includedNodes(
        from candidates: [(document: Document, hopDistance: Int)],
        libraryId: UUID,
        in context: ModelContext
    ) -> [(document: Document, hopDistance: Int)] {
        candidates.filter { candidate in
            let hasOpenTasks = GraphNodeClassifier.hasOpenTasks(candidate.document, in: context)
            let isOrphan = GraphNodeClassifier.isOrphan(candidate.document, libraryId: libraryId, in: context)
            if hasOpenTasks, showNotesWithOpenTasks { return true }
            if isOrphan, showOrphans { return true }
            if !hasOpenTasks, !isOrphan, showPlainNotes { return true }
            return false
        }
    }

    /// Tag-scoped *highlighting*, not filtering (Decision 5) — a matching node is styled
    /// distinctly, never hidden, so a highlight scope can never shrink the visible graph.
    func isHighlighted(_ document: Document) -> Bool {
        guard let tagScope, !tagScope.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return GraphNodeClassifier.matchesTag(document, tag: tagScope)
    }

}

/// Per-node classification `GraphFilter` filters/highlights by.
enum GraphNodeClassifier {

    static func hasOpenTasks(_ document: Document, in context: ModelContext) -> Bool {
        guard let documentId = document.documentId else { return false }
        return TaskDAL.fetchActive(documentId: documentId, in: context).contains { $0.isDone != true }
    }

    /// A node's own library-wide connectivity (not just its connection into the currently
    /// displayed neighborhood) — matches `GraphInsightsDAL.orphans`' definition. A node reached
    /// via a real link necessarily has at least one link (the one that reached it), so this
    /// naturally never matches for anything a neighborhood BFS actually found; it exists for
    /// nodes brought into view some other way (e.g. a future non-link-based inclusion) and for
    /// direct unit testing of the classification itself.
    static func isOrphan(_ document: Document, libraryId: UUID, in context: ModelContext) -> Bool {
        GraphDAL.directLinks(for: document, libraryId: libraryId, in: context).isEmpty
    }

    static func matchesTag(_ document: Document, tag: String) -> Bool {
        TagParser.extractAllTags(from: document.content ?? "").contains(TagParser.canonicalize(tag))
    }

}
