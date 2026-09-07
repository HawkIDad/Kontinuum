// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasBindingTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

/// Workstream C (`NoteBytez20260829v2-Enhancements.md`) — bidirectional graph ↔ canvas binding.
/// Decision 9(a): links → canvas, read-mostly. Decision 10: fixed at 1 hop.
struct CanvasBindingTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, CanvasBoard.self, CanvasCard.self, CanvasConnector.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func bindingSeedsTheBoardLikeAOneShotSend() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Source", content: "[[Leaf]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf", content: "", libraryId: libraryId, in: context)
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)

        CanvasDAL.bind(board, to: source, in: context)

        let boardId = try #require(board.canvasBoardId)
        #expect(board.boundDocumentId == source.documentId)
        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).count == 2)
        #expect(CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context).count == 1)
    }

    @Test func reconcilingAfterANewLinkAddsExactlyOneCardAndLeavesExistingCardsUntouched() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Source", content: "[[Leaf One]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf One", content: "", libraryId: libraryId, in: context)
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        CanvasDAL.bind(board, to: source, in: context)
        let boardId = try #require(board.canvasBoardId)

        // The user repositions the existing cards and drops in a web card.
        let existingCards = CanvasDAL.fetchActiveCards(boardId: boardId, in: context)
        for card in existingCards {
            CanvasDAL.moveCard(card, x: 999, y: 888, in: context)
        }
        let webCard = CanvasDAL.addWebCard(url: "https://example.com", boardId: boardId, x: 10, y: 10, in: context)

        DocumentDAL.updateContent(source, content: "[[Leaf One]] [[Leaf Two]]", in: context)
        _ = DocumentDAL.create(title: "Leaf Two", content: "", libraryId: libraryId, in: context)
        CanvasDAL.reconcileBoundBoard(board, in: context)

        let cardsAfter = CanvasDAL.fetchActiveCards(boardId: boardId, in: context)
        #expect(cardsAfter.count == 4) // source + Leaf One + Leaf Two + the web card
        // Existing cards' user-set positions are untouched.
        for card in existingCards {
            let refetched = try #require(cardsAfter.first { $0.canvasCardId == card.canvasCardId })
            #expect(refetched.positionX == 999)
            #expect(refetched.positionY == 888)
        }
        #expect(cardsAfter.contains { $0.canvasCardId == webCard.canvasCardId })
    }

    @Test func removingALinkRemovesOnlyItsCardAndConnectorsNeverAUserPlacedWebCard() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Source", content: "[[Leaf One]] [[Leaf Two]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf One", content: "", libraryId: libraryId, in: context)
        let leafTwo = DocumentDAL.create(title: "Leaf Two", content: "", libraryId: libraryId, in: context)
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        CanvasDAL.bind(board, to: source, in: context)
        let boardId = try #require(board.canvasBoardId)
        let webCard = CanvasDAL.addWebCard(url: "https://example.com", boardId: boardId, x: 0, y: 0, in: context)

        DocumentDAL.updateContent(source, content: "[[Leaf One]]", in: context)
        CanvasDAL.reconcileBoundBoard(board, in: context)

        let cardsAfter = CanvasDAL.fetchActiveCards(boardId: boardId, in: context)
        #expect(!cardsAfter.contains { $0.documentId == leafTwo.documentId })
        #expect(cardsAfter.contains { $0.canvasCardId == webCard.canvasCardId })
        #expect(cardsAfter.count == 3) // source + Leaf One + the untouched web card
    }

    @Test func reconciliationNeverTouchesAUserDrawnConnectorInvolvingANonNoteCard() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Source", content: "[[Leaf]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf", content: "", libraryId: libraryId, in: context)
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        CanvasDAL.bind(board, to: source, in: context)
        let boardId = try #require(board.canvasBoardId)

        let webCard = CanvasDAL.addWebCard(url: "https://example.com", boardId: boardId, x: 0, y: 0, in: context)
        let sourceCard = try #require(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).first { $0.documentId == source.documentId })
        let userConnector = CanvasDAL.addConnector(
            from: try #require(sourceCard.canvasCardId), to: try #require(webCard.canvasCardId), boardId: boardId, in: context
        )

        CanvasDAL.reconcileBoundBoard(board, in: context)

        #expect(CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context).contains { $0.canvasConnectorId == userConnector.canvasConnectorId })
    }

    @Test func unbindingStopsFurtherReconciliation() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Source", content: "[[Leaf]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf", content: "", libraryId: libraryId, in: context)
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        CanvasDAL.bind(board, to: source, in: context)
        let boardId = try #require(board.canvasBoardId)

        CanvasDAL.unbind(board, in: context)
        DocumentDAL.updateContent(source, content: "[[Leaf]] [[Another]]", in: context)
        _ = DocumentDAL.create(title: "Another", content: "", libraryId: libraryId, in: context)
        CanvasDAL.reconcileBoundBoard(board, in: context)

        #expect(board.boundDocumentId == nil)
        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).count == 2)
    }

    // MARK: - Open-as-bound-canvas (C7)

    @Test func boundBoardForDocumentReusesAnExistingBoundBoardRatherThanCreatingASecond() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Source", content: "[[Leaf]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf", content: "", libraryId: libraryId, in: context)

        let first = try #require(CanvasDAL.boundBoard(for: source, libraryId: libraryId, in: context))
        #expect(first.boundDocumentId == source.documentId)
        #expect(CanvasDAL.fetchActiveCards(boardId: try #require(first.canvasBoardId), in: context).count == 2)

        let second = try #require(CanvasDAL.boundBoard(for: source, libraryId: libraryId, in: context))
        #expect(second.canvasBoardId == first.canvasBoardId)
        #expect(CanvasDAL.fetchBoundBoards(boundTo: try #require(source.documentId), in: context).count == 1)
    }

    // MARK: - Reconciliation trigger (C4)

    @Test func savingTheBoundDocumentReconcilesItsBoardsAutomatically() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Source", content: "[[Leaf One]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf One", content: "", libraryId: libraryId, in: context)
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        CanvasDAL.bind(board, to: source, in: context)
        let boardId = try #require(board.canvasBoardId)

        _ = DocumentDAL.create(title: "Leaf Two", content: "", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: source, modelContext: context)
        viewModel.content = "[[Leaf One]] [[Leaf Two]]"
        viewModel.save()

        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).count == 3)
    }

    @Test func savingAnUnboundDocumentDoesNotTouchAnyBoard() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let unrelated = DocumentDAL.create(title: "Unrelated", content: "Plain text.", libraryId: libraryId, in: context)
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)

        let viewModel = DocumentViewModel(document: unrelated, modelContext: context)
        viewModel.content = "Edited."
        viewModel.save()

        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).isEmpty)
    }

    @Test func exportDropsBoundDocumentIdAndRoundTripsClean() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Source", content: "[[Leaf]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf", content: "", libraryId: libraryId, in: context)
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        CanvasDAL.bind(board, to: source, in: context)

        let json = CanvasDAL.exportJSONCanvas(board: board, in: context)

        #expect(!json.contains("boundDocumentId"))
        let decoded = try JSONDecoder().decode(JSONCanvasDocument.self, from: try #require(json.data(using: .utf8)))
        #expect(decoded.nodes.count == 2)
    }

}
