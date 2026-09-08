// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BacklinkDALTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct BacklinkDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func findBacklinksReturnsDocumentsWithMatchingWikilink() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target Note", content: "", libraryId: libraryId, in: context)
        let source = DocumentDAL.create(title: "Source Note", content: "See [[Target Note]] for context.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Unrelated", content: "Nothing here.", libraryId: libraryId, in: context)

        let targetId = try #require(target.documentId)
        let matches = BacklinkDAL.findBacklinks(to: "Target Note", excluding: targetId, libraryId: libraryId, in: context)

        #expect(matches.count == 1)
        #expect(matches.first?.sourceDocument.documentId == source.documentId)
        #expect(matches.first?.snippet.contains("Target Note") == true)
    }

    @Test func findBacklinksIsCaseInsensitive() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target Note", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Source", content: "[[target note]]", libraryId: libraryId, in: context)

        let targetId = try #require(target.documentId)
        let matches = BacklinkDAL.findBacklinks(to: "Target Note", excluding: targetId, libraryId: libraryId, in: context)

        #expect(matches.count == 1)
    }

    @Test func findUnlinkedMentionsMatchesPlainTextTitle() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Source", content: "This mentions Target Note without linking it.", libraryId: libraryId, in: context)

        let matches = BacklinkDAL.findUnlinkedMentions(to: "Target Note", excludingDocumentIds: [], libraryId: libraryId, in: context)

        #expect(matches.count == 1)
        #expect(matches.first?.snippet.contains("Target Note") == true)
    }

    @Test func findUnlinkedMentionsExcludesGivenDocumentIds() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Source", content: "Mentions Target Note here.", libraryId: libraryId, in: context)

        let sourceId = try #require(source.documentId)
        let matches = BacklinkDAL.findUnlinkedMentions(to: "Target Note", excludingDocumentIds: [sourceId], libraryId: libraryId, in: context)

        #expect(matches.isEmpty)
    }

    @Test func findUnlinkedMentionsReturnsEmptyForBlankTitle() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Source", content: "Some content.", libraryId: libraryId, in: context)

        let matches = BacklinkDAL.findUnlinkedMentions(to: "   ", excludingDocumentIds: [], libraryId: libraryId, in: context)

        #expect(matches.isEmpty)
    }

}
