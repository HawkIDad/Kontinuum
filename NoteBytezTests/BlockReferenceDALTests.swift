// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BlockReferenceDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct BlockReferenceDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - resolve

    @Test func resolveFindsABlockRegardlessOfWhichDocumentContainsIt() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target Note", content: "# Review PR\n\nSome detail.", libraryId: libraryId, in: context)
        let targetId = try #require(target.documentId)
        let targetBlock = try #require(BlockDAL.fetchActive(documentId: targetId, in: context).first)

        let resolved = BlockReferenceDAL.resolve(anchor: try #require(targetBlock.anchor), preferringDocumentId: nil, libraryId: libraryId, in: context)

        #expect(resolved?.block.blockId == targetBlock.blockId)
        #expect(resolved?.document.documentId == targetId)
    }

    @Test func resolveReturnsNilForAnUnknownAnchor() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Note", content: "Some content.", libraryId: libraryId, in: context)

        #expect(BlockReferenceDAL.resolve(anchor: "does-not-exist", preferringDocumentId: nil, libraryId: libraryId, in: context) == nil)
    }

    @Test func resolvePrefersAMatchInTheGivenDocumentWhenAnchorsCollideAcrossDocuments() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let documentA = DocumentDAL.create(title: "A", content: "# Shared Anchor\n\nFrom A.", libraryId: libraryId, in: context)
        let documentB = DocumentDAL.create(title: "B", content: "# Shared Anchor\n\nFrom B.", libraryId: libraryId, in: context)
        let documentAId = try #require(documentA.documentId)
        let documentBId = try #require(documentB.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: documentAId, in: context).first?.anchor)
        // Both documents' first block shares the same anchor text ("shared-anchor").
        #expect(BlockDAL.fetchActive(documentId: documentBId, in: context).first?.anchor == anchor)

        let resolved = BlockReferenceDAL.resolve(anchor: anchor, preferringDocumentId: documentBId, libraryId: libraryId, in: context)

        #expect(resolved?.document.documentId == documentBId)
    }

    @Test func resolveFallsBackToDeterministicLibraryWideMatchWhenNoPreferenceGiven() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let documentZ = DocumentDAL.create(title: "Z Note", content: "# Shared Anchor\n\nFrom Z.", libraryId: libraryId, in: context)
        let documentA = DocumentDAL.create(title: "A Note", content: "# Shared Anchor\n\nFrom A.", libraryId: libraryId, in: context)
        let documentZId = try #require(documentZ.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: documentZId, in: context).first?.anchor)

        let resolved = BlockReferenceDAL.resolve(anchor: anchor, preferringDocumentId: nil, libraryId: libraryId, in: context)

        // "A Note" sorts before "Z Note" — deterministic tie-break by document title.
        #expect(resolved?.document.documentId == documentA.documentId)
    }

    // MARK: - autocompleteMatches

    @Test func autocompleteMatchesFuzzyMatchesAnchorOrContent() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Note", content: "# Review PR from Dana\n\nUnrelated block.", libraryId: libraryId, in: context)

        let matches = BlockReferenceDAL.autocompleteMatches(query: "revpr", libraryId: libraryId, in: context)

        #expect(matches.contains { $0.anchor == "review-pr-from-dana" })
    }

    @Test func autocompleteMatchesFuzzyMatchesHeadingPathEvenWhenAnchorAndContentDoNotContainTheQuery() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Note", content: "# Financials\n\n## Budget\n\nSome numbers.", libraryId: libraryId, in: context)

        let matches = BlockReferenceDAL.autocompleteMatches(query: "budget", libraryId: libraryId, in: context)

        #expect(matches.contains { $0.content == "Some numbers." })
    }

    @Test func autocompleteMatchesReturnsEveryBlockForAnEmptyQuery() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Note", content: "First.\n\nSecond.", libraryId: libraryId, in: context)

        #expect(BlockReferenceDAL.autocompleteMatches(query: "", libraryId: libraryId, in: context).count == 2)
    }

    // MARK: - findBlockBacklinks

    @Test func findBlockBacklinksReturnsDocumentsReferencingThatAnchor() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target", content: "# Review PR\n\nDetail.", libraryId: libraryId, in: context)
        let targetId = try #require(target.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: targetId, in: context).first?.anchor)
        let source = DocumentDAL.create(title: "Source", content: "See ((\(anchor))) for context.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Unrelated", content: "No reference here.", libraryId: libraryId, in: context)

        let matches = BlockReferenceDAL.findBlockBacklinks(to: anchor, excluding: targetId, libraryId: libraryId, in: context)

        #expect(matches.count == 1)
        #expect(matches.first?.sourceDocument.documentId == source.documentId)
        #expect(matches.first?.snippet.contains(anchor) == true)
    }

    @Test func findBlockBacklinksIncludesADocumentThatEmbedsTheAnchorRatherThanJustLinkingIt() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target", content: "# Review PR\n\nDetail.", libraryId: libraryId, in: context)
        let targetId = try #require(target.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: targetId, in: context).first?.anchor)
        let source = DocumentDAL.create(title: "Source", content: "See !((\(anchor))) for the live copy.", libraryId: libraryId, in: context)

        let matches = BlockReferenceDAL.findBlockBacklinks(to: anchor, excluding: targetId, libraryId: libraryId, in: context)

        #expect(matches.contains { $0.sourceDocument.documentId == source.documentId })
    }

    @Test func findBlockBacklinksExcludesTheGivenDocumentEvenIfItSelfReferences() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "# Review PR\n\nSee ((review-pr)) above.", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let matches = BlockReferenceDAL.findBlockBacklinks(to: "review-pr", excluding: documentId, libraryId: libraryId, in: context)

        #expect(matches.isEmpty)
    }

    @Test func findBlockBacklinksReturnsEmptyWhenNoDocumentReferencesTheAnchor() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target", content: "# Review PR\n\nDetail.", libraryId: libraryId, in: context)
        let targetId = try #require(target.documentId)
        _ = DocumentDAL.create(title: "Unrelated", content: "No reference here.", libraryId: libraryId, in: context)

        #expect(BlockReferenceDAL.findBlockBacklinks(to: "review-pr", excluding: targetId, libraryId: libraryId, in: context).isEmpty)
    }

}
