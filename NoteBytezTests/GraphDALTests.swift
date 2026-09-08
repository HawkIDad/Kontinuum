// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct GraphDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func directLinksIncludesOutgoingWikilinkTargets() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Roadmap", content: "", libraryId: libraryId, in: context)
        let source = DocumentDAL.create(title: "Weekly Review", content: "See [[Roadmap]] for details.", libraryId: libraryId, in: context)

        let links = GraphDAL.directLinks(for: source, libraryId: libraryId, in: context)

        #expect(links.map { $0.documentId } == [target.documentId])
    }

    @Test func directLinksIncludesIncomingBacklinks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Roadmap", content: "", libraryId: libraryId, in: context)
        let source = DocumentDAL.create(title: "Weekly Review", content: "See [[Roadmap]] for details.", libraryId: libraryId, in: context)

        let links = GraphDAL.directLinks(for: target, libraryId: libraryId, in: context)

        #expect(links.map { $0.documentId } == [source.documentId])
    }

    @Test func directLinksExcludesUnrelatedDocuments() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Weekly Review", content: "Nothing linked here.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Unrelated", content: "No connection.", libraryId: libraryId, in: context)

        let links = GraphDAL.directLinks(for: source, libraryId: libraryId, in: context)

        #expect(links.isEmpty)
    }

    @Test func directLinksDedupesADocumentLinkedInBothDirections() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let noteA = DocumentDAL.create(title: "Note A", content: "[[Note B]]", libraryId: libraryId, in: context)
        let noteB = DocumentDAL.create(title: "Note B", content: "[[Note A]]", libraryId: libraryId, in: context)

        let links = GraphDAL.directLinks(for: noteA, libraryId: libraryId, in: context)

        #expect(links.count == 1)
        #expect(links.first?.documentId == noteB.documentId)
    }

    /// The load-bearing guarantee for Phase 11: the graph's incoming edges must be exactly
    /// what S5's Backlinks Pane already shows, computed via the very same `BacklinkDAL` call —
    /// so the two views can never drift apart.
    @Test func incomingEdgesMatchBacklinkDALExactly() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Roadmap", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Weekly Review", content: "[[Roadmap]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Standup Notes", content: "[[Roadmap]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Unrelated", content: "No link here.", libraryId: libraryId, in: context)

        let targetId = try #require(target.documentId)
        let backlinkIds = Set(BacklinkDAL.findBacklinks(to: "Roadmap", excluding: targetId, libraryId: libraryId, in: context).compactMap { $0.sourceDocument.documentId })
        let graphIds = Set(GraphDAL.directLinks(for: target, libraryId: libraryId, in: context).compactMap { $0.documentId })

        #expect(graphIds == backlinkIds)
    }

    @Test func directLinksReturnsEmptyForBlankTitleAndContent() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Other", content: "Some content.", libraryId: libraryId, in: context)

        let links = GraphDAL.directLinks(for: source, libraryId: libraryId, in: context)

        #expect(links.isEmpty)
    }

}
