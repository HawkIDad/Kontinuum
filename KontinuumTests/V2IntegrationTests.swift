// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  V2IntegrationTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

/// `NoteBytez20260829v2-Enhancements.md` Workstream E, E6 journey acceptance — the shipped
/// slice (A/B/C). Journeys (d)/(e)/(e′)/(f) belong to Workstream D and are omitted until the
/// D-gate clears. Same end-to-end shape as `FlowEnhancementsIntegrationTests`.
struct V2IntegrationTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self,
            DocumentNotebook.self, TaskItem.self, Property.self, DocumentProperty.self, SavedView.self,
            CanvasBoard.self, CanvasCard.self, CanvasConnector.self, Attachment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - (a) Force-graph filter → save as view → reopen

    @Test func forceGraphFilterSavesAsAViewAndReopensWithTheSameFilterAndFocus() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let libraryId = try #require(library.libraryId)

        let focus = DocumentDAL.create(title: "Hub", content: "[[Spoke A]] [[Spoke B]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Spoke A", content: "[[Spoke C]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Spoke B", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Spoke C", content: "", libraryId: libraryId, in: context)

        let viewModel = GraphViewModel(document: focus, modelContext: context, initialMode: .force)
        viewModel.filter.depth = 2
        viewModel.filter.showOrphans = false
        viewModel.filter.tagScope = "worldbuilding"

        let saved = try #require(viewModel.saveFilterAsView(name: "Two Hops, No Orphans"))
        #expect(saved.savedQueryType == .graph)

        // Reopen: fetch the saved view, decode its definition, rebuild the graph from it.
        let reloaded = try #require(SavedViewDAL.fetchActive(libraryId: libraryId, in: context).first { $0.savedViewId == saved.savedViewId })
        let definition = try #require(reloaded.graphDefinition)
        #expect(definition.focusDocumentId == focus.documentId)

        let reopened = GraphViewModel(
            document: focus,
            modelContext: context,
            initialMode: .force,
            initialFilter: definition.filter
        )
        #expect(reopened.filter.depth == 2)
        #expect(reopened.filter.showOrphans == false)
        #expect(reopened.filter.tagScope == "worldbuilding")
        // depth=2 reaches Spoke C through Spoke A; a depth-1 view would not.
        #expect(reopened.neighborhood.contains { $0.document.title == "Spoke C" })
    }

    // MARK: - (b) Edit a transcluded block with a mid-edit source change

    /// The plan's E6(b) prose predates the B-gate resolution. Decision 6 resolved to (a)
    /// optimistic, last-write-wins — no merge prompt — so this journey verifies exactly that:
    /// a concurrent source edit is silently overwritten by the later transclusion commit, and
    /// both notes end consistent.
    @Test func editingATranscludedBlockWithAConcurrentSourceChangeEndsLastWriteWinsAndConsistent() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let libraryId = try #require(library.libraryId)

        let source = DocumentDAL.create(title: "Meeting Notes", content: "# Action Items\n\nFollow up with Dana.", libraryId: libraryId, in: context)
        let sourceId = try #require(source.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.content == "Follow up with Dana." }?.anchor)

        let embedding = DocumentDAL.create(title: "Journal", content: "Recap:\n\n!((\(anchor))) noted.", libraryId: libraryId, in: context)
        let embeddingViewModel = DocumentViewModel(document: embedding, modelContext: context)

        // A concurrent editor changes the source block after the embed rendered.
        DocumentDAL.updateContent(source, content: "# Action Items\n\nFollow up with Dana urgently.", in: context)

        // The in-place transclusion edit commits later — it wins, no prompt.
        let committed = embeddingViewModel.commitTransclusionEdit(anchor: anchor, newText: "Follow up with Dana about the Q3 budget.")
        #expect(committed)

        // Source note reflects the transclusion edit.
        #expect(source.content == "# Action Items\n\nFollow up with Dana about the Q3 budget.")
        let sourceBlock = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.anchor == anchor })
        #expect(sourceBlock.content == "Follow up with Dana about the Q3 budget.")

        // Embedding note re-renders the same text; its own on-disk content still carries only the sigil.
        let reResolved = try #require(embeddingViewModel.transclusion(for: anchor))
        #expect(reResolved.block.content == "Follow up with Dana about the Q3 budget.")
        #expect(embedding.content == "Recap:\n\n!((\(anchor))) noted.")
        #expect(ExportDAL.exportableContent(for: embedding, in: context).contains("!((\(anchor)))"))
    }

    // MARK: - (c) Bind a board → mutate links → board tracks, layout intact → connector creates a backlink

    @Test func boundBoardTracksLinkChangesKeepsLayoutAndAConfirmedConnectorWritesTheBacklink() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let libraryId = try #require(library.libraryId)

        let source = DocumentDAL.create(title: "Source", content: "[[Leaf One]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf One", content: "", libraryId: libraryId, in: context)
        let leafTwo = DocumentDAL.create(title: "Leaf Two", content: "", libraryId: libraryId, in: context)

        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        CanvasDAL.bind(board, to: source, in: context)
        let boardId = try #require(board.canvasBoardId)
        #expect(board.boundDocumentId == source.documentId)
        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).count == 2) // source + Leaf One

        // User arranges the two existing note cards and drops a web card.
        let arrangedCardIds = Set(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).compactMap { card -> UUID? in
            CanvasDAL.moveCard(card, x: 500, y: 400, in: context)
            return card.canvasCardId
        })
        let webCard = CanvasDAL.addWebCard(url: "https://example.com", boardId: boardId, x: 20, y: 20, in: context)

        // Links mutate; saving the bound doc reconciles the board automatically (C4 trigger).
        let sourceViewModel = DocumentViewModel(document: source, modelContext: context)
        sourceViewModel.content = "[[Leaf One]] [[Leaf Two]]"
        sourceViewModel.save()

        let cardsAfterAdd = CanvasDAL.fetchActiveCards(boardId: boardId, in: context)
        #expect(cardsAfterAdd.count == 4) // source + Leaf One + Leaf Two + web card
        #expect(cardsAfterAdd.contains { $0.documentId == leafTwo.documentId })
        // The cards the user arranged keep their positions; only the freshly-added card is laid out.
        for card in cardsAfterAdd where arrangedCardIds.contains(card.canvasCardId ?? UUID()) {
            #expect(card.positionX == 500)
            #expect(card.positionY == 400)
        }
        #expect(cardsAfterAdd.contains { $0.canvasCardId == webCard.canvasCardId })

        // Removing a link drops only its card, never the user's web card.
        sourceViewModel.content = "[[Leaf One]]"
        sourceViewModel.save()
        let cardsAfterRemove = CanvasDAL.fetchActiveCards(boardId: boardId, in: context)
        #expect(!cardsAfterRemove.contains { $0.documentId == leafTwo.documentId })
        #expect(cardsAfterRemove.contains { $0.canvasCardId == webCard.canvasCardId })

        // C6: a confirmed note-to-note connector writes the matching [[link]] into the source
        // document, then the board reconciles and shows the new card.
        let leafThree = DocumentDAL.create(title: "Leaf Three", content: "", libraryId: libraryId, in: context)
        DocumentDAL.appendWikilink(to: source, title: "Leaf Three", in: context)
        sourceViewModel.content = try #require(source.content)
        sourceViewModel.save()

        #expect(WikilinkParser.extractTitles(from: try #require(source.content)).contains("Leaf Three"))
        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).contains { $0.documentId == leafThree.documentId })
    }

}
