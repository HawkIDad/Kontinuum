// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BacklinksViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

@Observable
final class BacklinksViewModel {

    /// Every other document that references one of this document's blocks via `((anchor))`,
    /// grouped by anchor — the block-granularity extension of `backlinks` above.
    struct BlockBacklinkGroup: Identifiable {
        let anchor: String
        let matches: [BacklinkMatch]
        var id: String { anchor }
    }

    private(set) var backlinks: [BacklinkMatch] = []
    private(set) var unlinkedMentions: [BacklinkMatch] = []
    private(set) var blockBacklinks: [BlockBacklinkGroup] = []

    private let document: Document
    private let modelContext: ModelContext

    init(document: Document, modelContext: ModelContext) {
        self.document = document
        self.modelContext = modelContext
        self.load()
    }

    func load() {
        guard let libraryId = document.libraryId,
              let documentId = document.documentId,
              let title = document.title,
              !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            backlinks = []
            unlinkedMentions = []
            blockBacklinks = []
            return
        }

        let linked = BacklinkDAL.findBacklinks(to: title, excluding: documentId, libraryId: libraryId, in: modelContext)
        var excludedIds = Set(linked.compactMap { $0.sourceDocument.documentId })
        excludedIds.insert(documentId)

        backlinks = linked
        unlinkedMentions = BacklinkDAL.findUnlinkedMentions(to: title, excludingDocumentIds: excludedIds, libraryId: libraryId, in: modelContext)

        let blocks = BlockDAL.fetchActive(documentId: documentId, in: modelContext)
        blockBacklinks = blocks.compactMap { block in
            guard let anchor = block.anchor else { return nil }
            let matches = BlockReferenceDAL.findBlockBacklinks(to: anchor, excluding: documentId, libraryId: libraryId, in: modelContext)
            guard !matches.isEmpty else { return nil }
            return BlockBacklinkGroup(anchor: anchor, matches: matches)
        }
    }

}
