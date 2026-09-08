// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  FlowEnhancementsIntegrationTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

/// `NoteBytez20260829v1-FlowEnhancements.md` Phase 7.6 acceptance: the five journeys the plan
/// names end-to-end, matching `JourneyIntegrationTests`'s existing shape for the MVP/R1 journeys.
struct FlowEnhancementsIntegrationTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self, DocumentNotebook.self, TaskItem.self, CanvasBoard.self, CanvasCard.self, CanvasConnector.self, Attachment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - Palette flow

    @Test func paletteFlowTypingInsightsAndActingTheTopHitNavigatesToInsights() throws {
        var navigatedTo: AppDestination?
        let viewModel = CommandPaletteViewModel(
            onNavigate: { navigatedTo = $0 },
            onAction: { _ in }
        )

        viewModel.query = "insights"
        let topHit = try #require(viewModel.results.first)

        #expect(topHit.id == AppCommand.navigate(.insights).id)
        viewModel.select(topHit)

        #expect(navigatedTo == .insights)
    }

    // MARK: - Resurfacing flow (closes the J4 "shallow graph" loop)

    @Test func resurfacingFlowAnOrphanWithAnUnlinkedMentionSurfacesThenLeavesOnceLinked() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let libraryId = try #require(library.libraryId)

        let forgotten = DocumentDAL.create(title: "Forgotten Idea", content: "An idea nobody revisited.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Journal", content: "Mentioned Forgotten Idea in passing today.", libraryId: libraryId, in: context)

        let firstSnapshot = GraphInsightsDAL.computeAll(libraryId: libraryId, in: context)
        #expect(firstSnapshot.orphans.map { $0.documentId }.contains(forgotten.documentId))
        #expect(!firstSnapshot.clusters.contains { $0.contains { $0.documentId == forgotten.documentId } && $0.count > 1 })

        DocumentDAL.updateContent(forgotten, content: "An idea nobody revisited. See [[Journal]].", in: context)

        let secondSnapshot = GraphInsightsDAL.computeAll(libraryId: libraryId, in: context)
        #expect(!secondSnapshot.orphans.map { $0.documentId }.contains(forgotten.documentId))
        #expect(secondSnapshot.clusters.contains { cluster in
            cluster.count > 1 && cluster.contains { $0.documentId == forgotten.documentId }
        })
    }

    // MARK: - Promote flow

    @Test func promoteFlowContextMenuPromoteCreatesADocumentInNotebookWithABidirectionalBacklinkLeavingSourceUntouchedAsideFromTheLink() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let libraryId = try #require(library.libraryId)
        let today = Date(timeIntervalSince1970: 1_700_000_000)

        let journalEntry = JournalDAL.fetchOrCreate(for: today, libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: journalEntry, modelContext: context)
        viewModel.content = "- Idea: ship the palette"
        viewModel.save()

        let notebook = NotebookDAL.create(name: "Ideas", libraryId: libraryId, in: context)
        let sortOrder = try #require(viewModel.blocks.first?.sortOrder)

        let promoted = try #require(viewModel.promoteBlock(at: sortOrder, into: notebook))

        #expect(NotebookDAL.fetchDocuments(for: notebook, in: context).map { $0.documentId }.contains(promoted.documentId))
        #expect(viewModel.content.hasPrefix("- Idea: ship the palette"))
        #expect(WikilinkParser.extractTitles(from: viewModel.content).contains(promoted.title ?? ""))
        #expect(WikilinkParser.extractTitles(from: promoted.content ?? "").contains(journalEntry.title ?? ""))
    }

    // MARK: - Transclusion flow

    @Test func transclusionFlowReflectsASubsequentSourceEditAndExportsTheLiteralSigil() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let libraryId = try #require(library.libraryId)

        let source = DocumentDAL.create(title: "Meeting Notes", content: "# Action Items\n\nFollow up with Dana.", libraryId: libraryId, in: context)
        let sourceId = try #require(source.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.content == "Follow up with Dana." }?.anchor)

        let journalEntry = DocumentDAL.create(title: "Journal", content: "Recap:\n\n!((\(anchor))) noted.", libraryId: libraryId, in: context)
        let journalViewModel = DocumentViewModel(document: journalEntry, modelContext: context)

        let resolved = try #require(journalViewModel.transclusion(for: anchor))
        #expect(resolved.block.content == "Follow up with Dana.")

        DocumentDAL.updateContent(source, content: "# Action Items\n\nFollow up with Dana about the budget.", in: context)

        let reResolved = try #require(journalViewModel.transclusion(for: anchor))
        #expect(reResolved.block.content == "Follow up with Dana about the budget.")

        // The embedding note's own exported file still carries the literal sigil — transclusion
        // is render-time only, never written back into content.
        #expect(ExportDAL.exportableContent(for: journalEntry, in: context).contains("!((\(anchor)))"))
    }

    // MARK: - Send to Canvas flow

    @Test func sendToCanvasFlowProducesABoardThatExportsValidJSONCanvas() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let libraryId = try #require(library.libraryId)

        let center = DocumentDAL.create(title: "Center", content: "[[Leaf One]] [[Leaf Two]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf One", content: "[[Leaf Two]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf Two", content: "", libraryId: libraryId, in: context)

        let board = try #require(CanvasDAL.seedBoard(fromNeighborhoodOf: center, libraryId: libraryId, in: context))
        let boardId = try #require(board.canvasBoardId)

        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).count == 3)
        #expect(CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context).count == 3)

        let json = CanvasDAL.exportJSONCanvas(board: board, in: context)
        let decoded = try JSONDecoder().decode(JSONCanvasDocument.self, from: try #require(json.data(using: .utf8)))
        #expect(decoded.nodes.count == 3)
        #expect(decoded.edges.count == 3)
    }

}
