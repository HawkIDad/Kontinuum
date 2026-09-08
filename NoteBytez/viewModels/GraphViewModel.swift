// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// S8's two render modes (Decision 4): Radial (MVP default, one-hop, no simulation) and Force
/// (opt-in, Workstream A) — a segmented control on `GraphView` switches between them.
enum GraphMode: String, CaseIterable, Identifiable {
    case radial
    case force
    var id: String { rawValue }
    var title: String { self == .radial ? "Radial" : "Force" }
}

@Observable
final class GraphViewModel {

    let document: Document
    private let modelContext: ModelContext

    /// Radial mode's node set — unchanged from MVP: `directLinks`, one hop, no filter.
    private(set) var linkedDocuments: [Document] = []

    /// Force mode's node set — `GraphDAL.neighborhood(of:depth:)` narrowed by `filter`.
    private(set) var neighborhood: [(document: Document, hopDistance: Int)] = []

    var mode: GraphMode
    var filter: GraphFilter {
        didSet {
            guard filter != oldValue else { return }
            refreshNeighborhood()
        }
    }

    init(document: Document, modelContext: ModelContext, initialMode: GraphMode = .radial, initialFilter: GraphFilter = GraphFilter()) {
        self.document = document
        self.modelContext = modelContext
        self.mode = initialMode
        self.filter = initialFilter
        load()
    }

    func load() {
        guard let libraryId = document.libraryId else {
            linkedDocuments = []
            neighborhood = []
            return
        }
        linkedDocuments = GraphDAL.directLinks(for: document, libraryId: libraryId, in: modelContext)
        refreshNeighborhood()
    }

    private func refreshNeighborhood() {
        guard let libraryId = document.libraryId else {
            neighborhood = []
            return
        }
        let candidates = GraphDAL.neighborhood(of: document, depth: filter.depth, libraryId: libraryId, in: modelContext)
        neighborhood = filter.includedNodes(from: candidates, libraryId: libraryId, in: modelContext)
    }

    func isHighlighted(_ document: Document) -> Bool {
        filter.isHighlighted(document)
    }

    /// Edges between any two members of the currently displayed force-mode graph (focus +
    /// neighborhood) — not just focus↔node, mirroring `CanvasDAL.seedBoard`'s own "every link
    /// between any two members" rule (v1 Decision 4) so the force layout reflects the real
    /// link structure, not just a star around the focus note.
    var forceModeEdges: [ForceDirectedLayout.Edge] {
        var members: [Document] = [document]
        members.append(contentsOf: neighborhood.map { $0.document })

        let membersByLowercasedTitle = Dictionary(members.compactMap { member -> (String, Document)? in
            guard let title = member.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return (title.lowercased(), member)
        }, uniquingKeysWith: { first, _ in first })

        var edges: [ForceDirectedLayout.Edge] = []
        for member in members {
            guard let memberId = member.documentId else { continue }
            for linkedTitle in WikilinkParser.extractTitles(from: member.content ?? "") {
                guard let target = membersByLowercasedTitle[linkedTitle.lowercased()],
                      let targetId = target.documentId, targetId != memberId
                else { continue }
                edges.append(ForceDirectedLayout.Edge(from: memberId, to: targetId))
            }
        }
        return edges
    }

    /// Persists the current force-mode filter as a `.graph` `SavedView` (A6's "Save as View").
    @discardableResult
    func saveFilterAsView(name: String) -> SavedView? {
        guard let libraryId = document.libraryId, let documentId = document.documentId else { return nil }
        let definition = SavedGraphDefinition(focusDocumentId: documentId, filter: filter)
        return SavedViewDAL.createGraphView(name: name, definition: definition, libraryId: libraryId, in: modelContext)
    }

}
