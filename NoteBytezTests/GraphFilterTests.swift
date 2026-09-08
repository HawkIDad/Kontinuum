// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphFilterTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct GraphFilterTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - GraphDAL.neighborhood depth

    @Test func depthOneYieldsExactlyDirectLinks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let root = DocumentDAL.create(title: "Root", content: "[[Leaf]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf", content: "[[Grandchild]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Grandchild", content: "", libraryId: libraryId, in: context)

        let neighborhood = GraphDAL.neighborhood(of: root, depth: 1, libraryId: libraryId, in: context)
        let directLinks = GraphDAL.directLinks(for: root, libraryId: libraryId, in: context)

        #expect(Set(neighborhood.map { $0.document.documentId }) == Set(directLinks.map { $0.documentId }))
        #expect(neighborhood.allSatisfy { $0.hopDistance == 1 })
    }

    @Test func depthTwoAddsTheFirstHopsOwnLinks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let root = DocumentDAL.create(title: "Root", content: "[[Leaf]]", libraryId: libraryId, in: context)
        let leaf = DocumentDAL.create(title: "Leaf", content: "[[Grandchild]]", libraryId: libraryId, in: context)
        let grandchild = DocumentDAL.create(title: "Grandchild", content: "", libraryId: libraryId, in: context)

        let neighborhood = GraphDAL.neighborhood(of: root, depth: 2, libraryId: libraryId, in: context)

        #expect(neighborhood.first { $0.document.documentId == leaf.documentId }?.hopDistance == 1)
        #expect(neighborhood.first { $0.document.documentId == grandchild.documentId }?.hopDistance == 2)
    }

    @Test func neighborhoodNeverIncludesTheRootItself() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let root = DocumentDAL.create(title: "Root", content: "[[Leaf]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf", content: "[[Root]]", libraryId: libraryId, in: context)

        let neighborhood = GraphDAL.neighborhood(of: root, depth: 2, libraryId: libraryId, in: context)

        #expect(!neighborhood.contains { $0.document.documentId == root.documentId })
    }

    // MARK: - GraphFilter node-type toggles

    @Test func showNotesWithOpenTasksIncludesANodeWithAnOpenTask() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let root = DocumentDAL.create(title: "Root", content: "[[Project]]", libraryId: libraryId, in: context)
        let project = DocumentDAL.create(title: "Project", content: "- [ ] Ship it", libraryId: libraryId, in: context)
        _ = TaskDAL.syncTasks(for: try #require(project.documentId), libraryId: libraryId, in: context)

        let neighborhood = GraphDAL.neighborhood(of: root, depth: 1, libraryId: libraryId, in: context)
        var filter = GraphFilter()
        filter.showPlainNotes = false
        filter.showOrphans = false

        let included = filter.includedNodes(from: neighborhood, libraryId: libraryId, in: context)

        #expect(included.contains { $0.document.documentId == project.documentId })
    }

    @Test func togglingOffNotesWithOpenTasksExcludesThatNode() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let root = DocumentDAL.create(title: "Root", content: "[[Project]]", libraryId: libraryId, in: context)
        let project = DocumentDAL.create(title: "Project", content: "- [ ] Ship it", libraryId: libraryId, in: context)
        _ = TaskDAL.syncTasks(for: try #require(project.documentId), libraryId: libraryId, in: context)

        let neighborhood = GraphDAL.neighborhood(of: root, depth: 1, libraryId: libraryId, in: context)
        var filter = GraphFilter()
        filter.showNotesWithOpenTasks = false
        filter.showPlainNotes = false
        filter.showOrphans = false

        let included = filter.includedNodes(from: neighborhood, libraryId: libraryId, in: context)

        #expect(!included.contains { $0.document.documentId == project.documentId })
    }

    @Test func showPlainNotesIncludesANodeWithNoOpenTasks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let root = DocumentDAL.create(title: "Root", content: "[[Plain Note]]", libraryId: libraryId, in: context)
        let plain = DocumentDAL.create(title: "Plain Note", content: "Just text.", libraryId: libraryId, in: context)

        let neighborhood = GraphDAL.neighborhood(of: root, depth: 1, libraryId: libraryId, in: context)
        var filter = GraphFilter()
        filter.showNotesWithOpenTasks = false
        filter.showOrphans = false

        let included = filter.includedNodes(from: neighborhood, libraryId: libraryId, in: context)

        #expect(included.contains { $0.document.documentId == plain.documentId })
    }

    @Test func classifierIsOrphanMatchesADocumentWithNoLinksOfItsOwn() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let lonely = DocumentDAL.create(title: "Lonely", content: "Nothing linked.", libraryId: libraryId, in: context)

        #expect(GraphNodeClassifier.isOrphan(lonely, libraryId: libraryId, in: context))
    }

    @Test func classifierIsOrphanIsFalseForADocumentWithAnyLink() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Source", content: "[[Target]]", libraryId: libraryId, in: context)

        #expect(!GraphNodeClassifier.isOrphan(target, libraryId: libraryId, in: context))
    }

    // MARK: - GraphFilter tag-scoped highlighting (not filtering)

    @Test func isHighlightedMatchesADocumentWithTheScopeTag() {
        let filter = GraphFilter(tagScope: "worldbuilding")
        let document = Document(title: "Map", content: "#worldbuilding notes", libraryId: UUID())
        #expect(filter.isHighlighted(document))
    }

    @Test func isHighlightedIsFalseWithoutTheTagOrWithNoScopeSet() {
        let withoutTag = Document(title: "Map", content: "No tags here.", libraryId: UUID())
        #expect(!GraphFilter(tagScope: "worldbuilding").isHighlighted(withoutTag))

        let withTag = Document(title: "Map", content: "#worldbuilding notes", libraryId: UUID())
        #expect(!GraphFilter(tagScope: nil).isHighlighted(withTag))
    }

    @Test func tagScopeNeverExcludesANodeFromIncludedNodes() throws {
        // Highlighting is additive styling only — it must never shrink the visible set.
        let context = try makeContext()
        let libraryId = UUID()
        let root = DocumentDAL.create(title: "Root", content: "[[Unrelated]]", libraryId: libraryId, in: context)
        let unrelated = DocumentDAL.create(title: "Unrelated", content: "No tags.", libraryId: libraryId, in: context)

        let neighborhood = GraphDAL.neighborhood(of: root, depth: 1, libraryId: libraryId, in: context)
        let filter = GraphFilter(tagScope: "worldbuilding")

        let included = filter.includedNodes(from: neighborhood, libraryId: libraryId, in: context)

        #expect(included.contains { $0.document.documentId == unrelated.documentId })
    }

}
