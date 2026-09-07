// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentDALTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct DocumentDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func createInsertsDocumentAndSyncsBlocks() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let document = DocumentDAL.create(title: "My Note", content: "First.\n\nSecond.", libraryId: libraryId, in: context)

        #expect(document.title == "My Note")
        #expect(document.isActive == true)

        let documentId = try #require(document.documentId)
        #expect(BlockDAL.fetchActive(documentId: documentId, in: context).count == 2)
    }

    @Test func fetchActiveScopesToLibrary() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let otherLibraryId = UUID()
        _ = DocumentDAL.create(title: "Mine", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Other", content: "", libraryId: otherLibraryId, in: context)

        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(documents.count == 1)
        #expect(documents.first?.title == "Mine")
    }

    @Test func updateContentResyncsBlocks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "Original.", libraryId: libraryId, in: context)

        DocumentDAL.updateContent(document, content: "Original.\n\nAdded.", in: context)

        let documentId = try #require(document.documentId)
        #expect(BlockDAL.fetchActive(documentId: documentId, in: context).count == 2)
    }

    @Test func softDeleteCascadesToBlocks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "Some content.", libraryId: libraryId, in: context)

        DocumentDAL.softDelete(document, in: context)

        #expect(document.isActive == false)
        let documentId = try #require(document.documentId)
        #expect(BlockDAL.fetchActive(documentId: documentId, in: context).isEmpty)
    }

    @Test func updateTitleRenamesWikilinksInOtherDocuments() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Old Title", content: "", libraryId: libraryId, in: context)
        let source = DocumentDAL.create(title: "Source", content: "See [[Old Title]] for details.", libraryId: libraryId, in: context)

        DocumentDAL.updateTitle(target, title: "New Title", in: context)

        #expect(target.title == "New Title")
        #expect(source.content == "See [[New Title]] for details.")
    }

    @Test func updateTitleResyncsBlocksOfRenamedDocumentsInOtherContent() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Old Title", content: "", libraryId: libraryId, in: context)
        let source = DocumentDAL.create(title: "Source", content: "See [[Old Title]] here.", libraryId: libraryId, in: context)

        DocumentDAL.updateTitle(target, title: "New Title", in: context)

        let sourceId = try #require(source.documentId)
        let blocks = BlockDAL.fetchActive(documentId: sourceId, in: context)
        #expect(blocks.first?.content == "See [[New Title]] here.")
    }

    @Test func updateTitleDoesNotTouchUnrelatedDocuments() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Old Title", content: "", libraryId: libraryId, in: context)
        let unrelated = DocumentDAL.create(title: "Unrelated", content: "No links here.", libraryId: libraryId, in: context)

        DocumentDAL.updateTitle(target, title: "New Title", in: context)

        #expect(unrelated.content == "No links here.")
    }

    @Test func updateTitleWithNoPriorTitleDoesNotScanOtherDocuments() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "", content: "", libraryId: libraryId, in: context)

        DocumentDAL.updateTitle(target, title: "First Title", in: context)

        #expect(target.title == "First Title")
    }

}
