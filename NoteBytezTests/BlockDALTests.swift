// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BlockDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct BlockDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func syncBlocksCreatesOneBlockPerChunkInOrder() throws {
        let context = try makeContext()
        let documentId = UUID()
        let markdown = "# Title\n\nFirst paragraph.\n\nSecond paragraph."

        let blocks = BlockDAL.syncBlocks(for: documentId, markdown: markdown, in: context)

        #expect(blocks.map { $0.content } == ["# Title", "First paragraph.", "Second paragraph."])
        #expect(blocks.map { $0.sortOrder } == [0, 1, 2])
    }

    @Test func unchangedBlocksKeepTheirBlockIdAcrossResync() throws {
        let context = try makeContext()
        let documentId = UUID()
        let original = "# Title\n\nFirst paragraph.\n\nSecond paragraph."

        let firstSync = BlockDAL.syncBlocks(for: documentId, markdown: original, in: context)
        let titleBlockId = firstSync[0].blockId
        let firstParagraphId = firstSync[1].blockId
        let secondParagraphId = firstSync[2].blockId

        let edited = "# Title\n\nFirst paragraph EDITED.\n\nSecond paragraph."
        let secondSync = BlockDAL.syncBlocks(for: documentId, markdown: edited, in: context)

        #expect(secondSync[0].blockId == titleBlockId)
        #expect(secondSync[1].content == "First paragraph EDITED.")
        // Feature B (sticky identity): editing a block in place no longer mints a new blockId —
        // the reclaim pass in `syncBlocks` matches it to its prior self by position/heading and
        // similarity, so an edit keeps the same blockId (and anchor) rather than churning it.
        #expect(secondSync[1].blockId == firstParagraphId)
        #expect(secondSync[2].blockId == secondParagraphId)
    }

    @Test func removedChunkSoftDeletesItsBlock() throws {
        let context = try makeContext()
        let documentId = UUID()
        let original = "First.\n\nSecond.\n\nThird."

        let firstSync = BlockDAL.syncBlocks(for: documentId, markdown: original, in: context)
        let secondBlockId = firstSync[1].blockId

        _ = BlockDAL.syncBlocks(for: documentId, markdown: "First.\n\nThird.", in: context)

        let active = BlockDAL.fetchActive(documentId: documentId, in: context)
        #expect(active.count == 2)
        #expect(!active.contains { $0.blockId == secondBlockId })
    }

    @Test func reorderedUnchangedChunksKeepTheirBlockIdsAndUpdateSortOrder() throws {
        let context = try makeContext()
        let documentId = UUID()

        let firstSync = BlockDAL.syncBlocks(for: documentId, markdown: "Alpha.\n\nBeta.", in: context)
        let alphaId = firstSync[0].blockId
        let betaId = firstSync[1].blockId

        let secondSync = BlockDAL.syncBlocks(for: documentId, markdown: "Beta.\n\nAlpha.", in: context)

        #expect(secondSync[0].blockId == betaId)
        #expect(secondSync[0].sortOrder == 0)
        #expect(secondSync[1].blockId == alphaId)
        #expect(secondSync[1].sortOrder == 1)
    }

    @Test func duplicateContentChunksGetUniqueAnchors() throws {
        let context = try makeContext()
        let documentId = UUID()

        let blocks = BlockDAL.syncBlocks(for: documentId, markdown: "# Getting Started\n\n# Getting Started", in: context)

        #expect(blocks[0].anchor == "getting-started")
        #expect(blocks[1].anchor == "getting-started-2")
    }

    @Test func duplicateFirstLinesUnderDifferentHeadingsGetPathDisambiguatedAnchors() throws {
        let context = try makeContext()
        let documentId = UUID()
        let markdown = "# A\n\n## Budget\n\ntext\n\n# B\n\n## Budget\n\ntext"

        let blocks = BlockDAL.syncBlocks(for: documentId, markdown: markdown, in: context)
        let budgetAnchors = blocks.filter { $0.content == "## Budget" }.map { $0.anchor }

        #expect(budgetAnchors == ["a-budget", "b-budget"])
    }

    @Test func aUniqueBlocksAnchorIsUnchangedFromTodaysOutput() throws {
        let context = try makeContext()
        let documentId = UUID()

        let blocks = BlockDAL.syncBlocks(for: documentId, markdown: "# Getting Started\n\nSome body text.", in: context)

        #expect(blocks[0].anchor == "getting-started")
        #expect(blocks[1].anchor == "some-body-text")
    }

    @Test func backfillHeadingPathsIfNeededPopulatesNilPathsWithoutChurningBlockId() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "# Heading\n\nbody", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let bodyBlock = try #require(BlockDAL.fetchActive(documentId: documentId, in: context).first { $0.content == "body" })
        bodyBlock.headingPath = nil
        let preMigrationBlockId = bodyBlock.blockId

        BlockDAL.backfillHeadingPathsIfNeeded(in: context)

        let migrated = try #require(BlockDAL.fetchActive(documentId: documentId, in: context).first { $0.blockId == preMigrationBlockId })
        #expect(migrated.headingPath == "Heading")
    }

    // MARK: - Sticky block identity (Feature B reclaim pass)

    @Test func editingOneWordInABlockReclaimsItsBlockIdAndAnchor() throws {
        let context = try makeContext()
        let documentId = UUID()
        let firstSync = BlockDAL.syncBlocks(for: documentId, markdown: "Alpha.\n\nThe quick brown fox jumps.", in: context)
        let targetBlockId = firstSync[1].blockId
        let targetAnchor = firstSync[1].anchor

        let secondSync = BlockDAL.syncBlocks(for: documentId, markdown: "Alpha.\n\nThe quick brown fox leaps.", in: context)

        #expect(secondSync[1].blockId == targetBlockId)
        #expect(secondSync[1].anchor == targetAnchor)
        #expect(secondSync[1].content == "The quick brown fox leaps.")
    }

    @Test func blockMovedAndLightlyEditedStillReclaimsItsBlockId() throws {
        let context = try makeContext()
        let documentId = UUID()
        let firstSync = BlockDAL.syncBlocks(for: documentId, markdown: "Intro.\n\nThe quick brown fox jumps over the lazy dog.\n\nOutro.", in: context)
        let targetBlockId = firstSync[1].blockId
        let targetAnchor = firstSync[1].anchor

        let secondSync = BlockDAL.syncBlocks(for: documentId, markdown: "The quick brown fox jumps over the very lazy dog.\n\nIntro.\n\nOutro.", in: context)

        let movedBlock = try #require(secondSync.first { $0.blockId == targetBlockId })
        #expect(movedBlock.sortOrder == 0)
        #expect(movedBlock.anchor == targetAnchor)
        #expect(movedBlock.content == "The quick brown fox jumps over the very lazy dog.")
    }

    @Test func blockDeletedOutrightWithNothingSimilarIsSoftDeletedWithoutAFalseReclaim() throws {
        let context = try makeContext()
        let documentId = UUID()
        let firstSync = BlockDAL.syncBlocks(for: documentId, markdown: "Keep.\n\nThe quick brown fox jumps over the lazy dog.", in: context)
        let removedBlockId = firstSync[1].blockId

        let secondSync = BlockDAL.syncBlocks(for: documentId, markdown: "Keep.", in: context)

        #expect(!secondSync.contains { $0.blockId == removedBlockId })
        #expect(!BlockDAL.fetchActive(documentId: documentId, in: context).contains { $0.blockId == removedBlockId })
    }

    @Test func blockSplitByAnInsertedBlankLineLetsTheLargerRemnantKeepTheBlockId() throws {
        let context = try makeContext()
        let documentId = UUID()
        let original = "Alpha bravo charlie delta echo foxtrot golf hotel india juliett kilo."
        let firstSync = BlockDAL.syncBlocks(for: documentId, markdown: original, in: context)
        let originalBlockId = firstSync[0].blockId

        let secondSync = BlockDAL.syncBlocks(for: documentId, markdown: "Alpha bravo charlie delta echo foxtrot golf hotel.\n\nindia juliett kilo.", in: context)

        #expect(secondSync[0].blockId == originalBlockId)
        #expect(secondSync[0].content == "Alpha bravo charlie delta echo foxtrot golf hotel.")
        #expect(secondSync[1].blockId != originalBlockId)
        #expect(secondSync[1].content == "india juliett kilo.")
    }

    @Test func twoNearIdenticalEditsResolveDeterministicallyByDocumentOrderOnATie() throws {
        let context = try makeContext()
        let documentId = UUID()
        let firstSync = BlockDAL.syncBlocks(for: documentId, markdown: "The report is ready.", in: context)
        let originalBlockId = firstSync[0].blockId

        let secondSync = BlockDAL.syncBlocks(for: documentId, markdown: "The report is ready now.\n\nThe report is ready too.", in: context)

        #expect(secondSync[0].blockId == originalBlockId)
        #expect(secondSync[0].content == "The report is ready now.")
        #expect(secondSync[1].blockId != originalBlockId)
        #expect(secondSync[1].content == "The report is ready too.")
    }

    @Test func fetchActiveByLibraryReturnsBlocksAcrossEveryDocumentInThatLibrary() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let noteOne = DocumentDAL.create(title: "One", content: "First block.", libraryId: libraryId, in: context)
        let noteTwo = DocumentDAL.create(title: "Two", content: "Second block.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Other Library", content: "Should not appear.", libraryId: UUID(), in: context)

        let blocks = BlockDAL.fetchActive(libraryId: libraryId, in: context)

        #expect(blocks.count == 2)
        #expect(Set(blocks.compactMap { $0.documentId }) == Set([noteOne.documentId, noteTwo.documentId].compactMap { $0 }))
    }

    @Test func fetchActiveByLibraryExcludesSoftDeletedBlocks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "One", content: "Keep.\n\nRemove.", libraryId: libraryId, in: context)
        _ = BlockDAL.syncBlocks(for: try #require(document.documentId), markdown: "Keep.", in: context)

        let blocks = BlockDAL.fetchActive(libraryId: libraryId, in: context)

        #expect(blocks.count == 1)
        #expect(blocks.first?.content == "Keep.")
    }

}
