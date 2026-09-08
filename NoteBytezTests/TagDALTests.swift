// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct TagDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func syncTagsCreatesTagsAndJoinsFromInlineAndFrontmatter() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "---\ntags: [Roadmap]\n---\nSee #mvp.", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let tags = TagDAL.syncTags(for: documentId, content: document.content ?? "", libraryId: libraryId, in: context)

        #expect(Set(tags.compactMap { $0.name }) == ["roadmap", "mvp"])
        #expect(TagDAL.fetchTags(for: documentId, in: context).count == 2)
    }

    @Test func findOrCreateDedupesByCanonicalNameRegardlessOfCase() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let first = TagDAL.findOrCreate(name: "Roadmap", libraryId: libraryId, in: context)
        let second = TagDAL.findOrCreate(name: "  roadmap  ", libraryId: libraryId, in: context)

        #expect(first.tagId == second.tagId)
        #expect(TagDAL.fetchActive(libraryId: libraryId, in: context).count == 1)
    }

    @Test func syncTagsRemovesJoinForATagNoLongerReferenced() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "#roadmap #mvp", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        TagDAL.syncTags(for: documentId, content: "#roadmap #mvp", libraryId: libraryId, in: context)
        #expect(TagDAL.fetchTags(for: documentId, in: context).count == 2)

        TagDAL.syncTags(for: documentId, content: "#roadmap only now", libraryId: libraryId, in: context)
        let remaining = TagDAL.fetchTags(for: documentId, in: context)

        #expect(remaining.count == 1)
        #expect(remaining.first?.name == "roadmap")
    }

    @Test func fetchDocumentsReturnsEveryDocumentTaggedWithATag() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let noteOne = DocumentDAL.create(title: "One", content: "#roadmap", libraryId: libraryId, in: context)
        let noteTwo = DocumentDAL.create(title: "Two", content: "#roadmap", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Three", content: "no tags here", libraryId: libraryId, in: context)

        let tag = TagDAL.findOrCreate(name: "roadmap", libraryId: libraryId, in: context)
        TagDAL.syncTags(for: try #require(noteOne.documentId), content: "#roadmap", libraryId: libraryId, in: context)
        TagDAL.syncTags(for: try #require(noteTwo.documentId), content: "#roadmap", libraryId: libraryId, in: context)

        let documents = TagDAL.fetchDocuments(for: tag, in: context)
        #expect(Set(documents.compactMap { $0.documentId }) == Set([noteOne.documentId, noteTwo.documentId].compactMap { $0 }))
    }

    /// Simulates the CloudKit-merge scenario `mergeDuplicates` exists for: two devices,
    /// offline, each independently create a "roadmap" tag before syncing — since CloudKit
    /// disallows `.unique`, the merge leaves two active `Tag` rows with the same canonical
    /// name. `mergeDuplicates` should collapse them back to one and preserve every document
    /// association.
    @Test func mergeDuplicatesCollapsesTagsWithTheSameCanonicalNameAndRepointsJoins() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let survivor = Tag(name: "roadmap", libraryId: libraryId)
        let duplicate = Tag(name: "roadmap", libraryId: libraryId)
        context.insert(survivor)
        context.insert(duplicate)

        let noteOne = DocumentDAL.create(title: "One", content: "", libraryId: libraryId, in: context)
        let noteTwo = DocumentDAL.create(title: "Two", content: "", libraryId: libraryId, in: context)
        let survivorId = try #require(survivor.tagId)
        let duplicateId = try #require(duplicate.tagId)
        context.insert(DocumentTag(documentId: try #require(noteOne.documentId), tagId: survivorId, libraryId: libraryId))
        context.insert(DocumentTag(documentId: try #require(noteTwo.documentId), tagId: duplicateId, libraryId: libraryId))

        #expect(TagDAL.fetchActive(libraryId: libraryId, in: context).count == 2)

        let survivors = TagDAL.mergeDuplicates(libraryId: libraryId, in: context)

        #expect(survivors.count == 1)
        #expect(TagDAL.fetchActive(libraryId: libraryId, in: context).count == 1)
        let mergedTag = try #require(survivors.first)
        let documents = TagDAL.fetchDocuments(for: mergedTag, in: context)
        #expect(Set(documents.compactMap { $0.documentId }) == Set([noteOne.documentId, noteTwo.documentId].compactMap { $0 }))
    }

    @Test func mergeDuplicatesLeavesDistinctTagsUntouched() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = TagDAL.findOrCreate(name: "roadmap", libraryId: libraryId, in: context)
        _ = TagDAL.findOrCreate(name: "mvp", libraryId: libraryId, in: context)

        let survivors = TagDAL.mergeDuplicates(libraryId: libraryId, in: context)

        #expect(survivors.count == 2)
        #expect(TagDAL.fetchActive(libraryId: libraryId, in: context).count == 2)
    }

}
