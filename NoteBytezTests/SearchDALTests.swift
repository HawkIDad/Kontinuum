// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SearchDALTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct SearchDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, TaskItem.self, Property.self, DocumentProperty.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func searchContentMatchesTitleOrBody() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Sync Log", content: "Fixed the reconnect race condition.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Kontinuum Roadmap", content: "Finalize conflict UI, ship by Friday.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Unrelated", content: "Nothing relevant here.", libraryId: libraryId, in: context)

        let results = SearchDAL.searchContent(query: "conflict", libraryId: libraryId, in: context)

        #expect(results.count == 1)
        #expect(results.first?.document.title == "Kontinuum Roadmap")
    }

    @Test func searchContentRanksATitleMatchAboveABodyOnlyMatch() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Weekly Review", content: "Mentions roadmap once in passing.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Roadmap", content: "The plan.", libraryId: libraryId, in: context)

        let results = SearchDAL.searchContent(query: "roadmap", libraryId: libraryId, in: context)

        #expect(results.map { $0.document.title } == ["Roadmap", "Weekly Review"])
    }

    @Test func searchContentReturnsEmptyForBlankQuery() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Note", content: "Body", libraryId: libraryId, in: context)

        #expect(SearchDAL.searchContent(query: "   ", libraryId: libraryId, in: context).isEmpty)
    }

    @Test func searchContentSnippetIsCenteredOnTheMatch() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let content = String(repeating: "x", count: 100) + "NEEDLE" + String(repeating: "y", count: 100)
        _ = DocumentDAL.create(title: "Note", content: content, libraryId: libraryId, in: context)

        let result = try #require(SearchDAL.searchContent(query: "needle", libraryId: libraryId, in: context).first)

        #expect(result.snippet.contains("NEEDLE"))
        #expect(result.snippet.count < content.count)
    }

    @Test func searchByTitleOnlyMatchesTitleNotBody() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Sync Log", content: "Mentions conflict resolution.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Conflict Handling", content: "Unrelated body text.", libraryId: libraryId, in: context)

        let results = SearchDAL.searchByTitle(query: "conflict", libraryId: libraryId, in: context)

        #expect(results.count == 1)
        #expect(results.first?.document.title == "Conflict Handling")
    }

    @Test func searchByTagMatchesPartialTagNameAndDedupesADocumentTaggedTwice() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "#roadmap #roadmap-v2", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        TagDAL.syncTags(for: documentId, content: "#roadmap #roadmap-v2", libraryId: libraryId, in: context)

        let results = SearchDAL.searchByTag(query: "roadmap", libraryId: libraryId, in: context)

        #expect(results.count == 1)
        #expect(results.first?.document.documentId == documentId)
    }

    @Test func searchByTagReturnsEmptyWhenNoTagMatches() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "#roadmap", libraryId: libraryId, in: context)
        TagDAL.syncTags(for: try #require(document.documentId), content: "#roadmap", libraryId: libraryId, in: context)

        #expect(SearchDAL.searchByTag(query: "nonexistent", libraryId: libraryId, in: context).isEmpty)
    }

    @Test func searchByPropertyMatchesPartialValueAndDedupesADocumentWithTwoMatchingProperties() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "---\nSpecies: Kethran\nHomeworld: Kethra Prime\n---\n", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        PropertyDAL.syncProperties(for: documentId, content: try #require(document.content), libraryId: libraryId, in: context)

        let results = SearchDAL.searchByProperty(query: "Keth", libraryId: libraryId, in: context)

        #expect(results.count == 1)
        #expect(results.first?.document.documentId == documentId)
    }

    @Test func searchByPropertyReturnsEmptyWhenNoValueMatches() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "---\nSpecies: Kethran\n---\n", libraryId: libraryId, in: context)
        PropertyDAL.syncProperties(for: try #require(document.documentId), content: try #require(document.content), libraryId: libraryId, in: context)

        #expect(SearchDAL.searchByProperty(query: "Human", libraryId: libraryId, in: context).isEmpty)
    }

    // MARK: - searchAdvanced (Phase 5)

    @Test func searchAdvancedMatchesTheReleaseFeaturesExampleQuery() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let match = DocumentDAL.create(title: "Elyra's Betrayal", content: "", libraryId: libraryId, in: context)
        let matchId = try #require(match.documentId)
        TagDAL.syncTags(for: matchId, content: "#character #act2", libraryId: libraryId, in: context)

        let resolvedButTagged = DocumentDAL.create(title: "Wrapped Up", content: "", libraryId: libraryId, in: context)
        let resolvedId = try #require(resolvedButTagged.documentId)
        TagDAL.syncTags(for: resolvedId, content: "#character #act2 #resolved", libraryId: libraryId, in: context)

        let results = SearchDAL.searchAdvanced(query: "#character AND #act2 NOT #resolved", scope: .content, libraryId: libraryId, in: context)

        #expect(results.count == 1)
        #expect(results.first?.document.documentId == matchId)
    }

    @Test func searchAdvancedCombinesATagTermWithAContentTermInOneQuery() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let match = DocumentDAL.create(title: "Note", content: "Dana proposed a promotion.", libraryId: libraryId, in: context)
        let matchId = try #require(match.documentId)
        TagDAL.syncTags(for: matchId, content: "#hr", libraryId: libraryId, in: context)
        let wrongTag = DocumentDAL.create(title: "Note Two", content: "Dana proposed a promotion.", libraryId: libraryId, in: context)
        TagDAL.syncTags(for: try #require(wrongTag.documentId), content: "#personal", libraryId: libraryId, in: context)

        let results = SearchDAL.searchAdvanced(query: "promotion AND #hr", scope: .content, libraryId: libraryId, in: context)

        #expect(results.count == 1)
        #expect(results.first?.document.documentId == matchId)
    }

    @Test func searchAdvancedRespectsPathScopeForBareTerms() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let titled = DocumentDAL.create(title: "Dragon's Lair", content: "Nothing relevant.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Unrelated", content: "A dragon appears in the body only.", libraryId: libraryId, in: context)

        let results = SearchDAL.searchAdvanced(query: "dragon", scope: .path, libraryId: libraryId, in: context)

        #expect(results.count == 1)
        #expect(results.first?.document.documentId == titled.documentId)
    }

    @Test func searchAdvancedFallsBackToLiteralMatchOnMalformedBooleanSyntax() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "Contains an unbalanced quote literally.", libraryId: libraryId, in: context)

        let results = SearchDAL.searchAdvanced(query: "\"unbalanced quote", scope: .content, libraryId: libraryId, in: context)

        #expect(results.count == 1)
        #expect(results.first?.document.documentId == document.documentId)
    }

    @Test func searchAdvancedReturnsEmptyForBlankQuery() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Note", content: "Something.", libraryId: libraryId, in: context)

        #expect(SearchDAL.searchAdvanced(query: "   ", scope: .content, libraryId: libraryId, in: context).isEmpty)
    }

    @Test func quickSwitcherMatchesFuzzyTitleSubsequence() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Weekly Review", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Sync Log", content: "", libraryId: libraryId, in: context)

        let matches = SearchDAL.quickSwitcherMatches(query: "wkrev", libraryId: libraryId, in: context)

        #expect(matches.map { $0.title } == ["Weekly Review"])
    }

    @Test func quickSwitcherWithEmptyQueryReturnsRecentDocumentsUpToLimit() throws {
        let context = try makeContext()
        let libraryId = UUID()
        for index in 0..<5 {
            _ = DocumentDAL.create(title: "Note \(index)", content: "", libraryId: libraryId, in: context)
        }

        let matches = SearchDAL.quickSwitcherMatches(query: "", libraryId: libraryId, in: context, limit: 3)

        #expect(matches.count == 3)
    }

    @Test func searchScopesAreLibraryIsolated() throws {
        let context = try makeContext()
        let libraryOne = UUID()
        let libraryTwo = UUID()
        _ = DocumentDAL.create(title: "Shared Title", content: "roadmap details", libraryId: libraryOne, in: context)
        _ = DocumentDAL.create(title: "Shared Title", content: "roadmap details", libraryId: libraryTwo, in: context)

        let results = SearchDAL.searchContent(query: "roadmap", libraryId: libraryOne, in: context)

        #expect(results.count == 1)
    }

}
