// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasDALTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct CanvasDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Attachment.self, CanvasBoard.self, CanvasCard.self, CanvasConnector.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - Board CRUD

    @Test func createBoardAndFetchActiveRoundTrips() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let board = CanvasDAL.createBoard(name: "Mystery Board", libraryId: libraryId, in: context)

        let fetched = CanvasDAL.fetchActiveBoards(libraryId: libraryId, in: context)
        #expect(fetched.count == 1)
        #expect(fetched.first?.canvasBoardId == board.canvasBoardId)
    }

    @Test func renameBoardUpdatesName() throws {
        let context = try makeContext()
        let board = CanvasDAL.createBoard(name: "Old Name", libraryId: UUID(), in: context)
        CanvasDAL.renameBoard(board, to: "New Name", in: context)
        #expect(board.name == "New Name")
    }

    @Test func deleteBoardCascadesToItsCardsAndConnectors() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let board = CanvasDAL.createBoard(name: "Mystery Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)
        let cardA = CanvasDAL.addWebCard(url: "https://example.com/a", boardId: boardId, x: 0, y: 0, in: context)
        let cardB = CanvasDAL.addWebCard(url: "https://example.com/b", boardId: boardId, x: 100, y: 100, in: context)
        CanvasDAL.addConnector(from: try #require(cardA.canvasCardId), to: try #require(cardB.canvasCardId), boardId: boardId, in: context)

        CanvasDAL.deleteBoard(board, in: context)

        #expect(CanvasDAL.fetchActiveBoards(libraryId: libraryId, in: context).isEmpty)
        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).isEmpty)
        #expect(CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context).isEmpty)
    }

    // MARK: - Card CRUD

    @Test func addNoteCardCreatesACardReferencingTheDocument() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)
        let document = DocumentDAL.create(title: "Suspect A", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let card = CanvasDAL.addNoteCard(documentId: documentId, boardId: boardId, x: 10, y: 20, in: context)

        #expect(card.canvasCardType == .note)
        #expect(card.documentId == documentId)
        #expect(card.positionX == 10)
        #expect(card.positionY == 20)
        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).count == 1)
    }

    @Test func moveCardUpdatesPosition() throws {
        let context = try makeContext()
        let board = CanvasDAL.createBoard(name: "Board", libraryId: UUID(), in: context)
        let boardId = try #require(board.canvasBoardId)
        let card = CanvasDAL.addGroupCard(label: "Group", boardId: boardId, x: 0, y: 0, in: context)

        CanvasDAL.moveCard(card, x: 250, y: 400, in: context)

        #expect(card.positionX == 250)
        #expect(card.positionY == 400)
    }

    @Test func resizeCardUpdatesSizeAndEnforcesAMinimum() throws {
        let context = try makeContext()
        let board = CanvasDAL.createBoard(name: "Board", libraryId: UUID(), in: context)
        let boardId = try #require(board.canvasBoardId)
        let card = CanvasDAL.addGroupCard(label: "Group", boardId: boardId, x: 0, y: 0, in: context)

        CanvasDAL.resizeCard(card, width: 300, height: 200, in: context)
        #expect(card.width == 300)
        #expect(card.height == 200)

        CanvasDAL.resizeCard(card, width: 5, height: 5, in: context)
        #expect(card.width == 60)
        #expect(card.height == 40)
    }

    @Test func removeCardCascadesToConnectorsTouchingIt() throws {
        let context = try makeContext()
        let board = CanvasDAL.createBoard(name: "Board", libraryId: UUID(), in: context)
        let boardId = try #require(board.canvasBoardId)
        let cardA = CanvasDAL.addWebCard(url: "https://a.example.com", boardId: boardId, x: 0, y: 0, in: context)
        let cardB = CanvasDAL.addWebCard(url: "https://b.example.com", boardId: boardId, x: 100, y: 0, in: context)
        let connector = CanvasDAL.addConnector(from: try #require(cardA.canvasCardId), to: try #require(cardB.canvasCardId), boardId: boardId, in: context)

        CanvasDAL.removeCard(cardA, in: context)

        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).map(\.canvasCardId) == [cardB.canvasCardId])
        #expect(connector.isActive == false)
    }

    // MARK: - Connector CRUD

    @Test func addConnectorStoresFromToSideColorAndLabel() throws {
        let context = try makeContext()
        let board = CanvasDAL.createBoard(name: "Board", libraryId: UUID(), in: context)
        let boardId = try #require(board.canvasBoardId)
        let cardA = CanvasDAL.addWebCard(url: "https://a.example.com", boardId: boardId, x: 0, y: 0, in: context)
        let cardB = CanvasDAL.addWebCard(url: "https://b.example.com", boardId: boardId, x: 100, y: 0, in: context)

        let connector = CanvasDAL.addConnector(from: try #require(cardA.canvasCardId), to: try #require(cardB.canvasCardId), boardId: boardId, fromSide: "right", toSide: "left", color: "#FF0000", label: "reveals", in: context)

        #expect(connector.fromSide == "right")
        #expect(connector.toSide == "left")
        #expect(connector.color == "#FF0000")
        #expect(connector.label == "reveals")
        #expect(CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context).count == 1)
    }

    @Test func removeConnectorSoftDeletesRatherThanRemoving() throws {
        let context = try makeContext()
        let board = CanvasDAL.createBoard(name: "Board", libraryId: UUID(), in: context)
        let boardId = try #require(board.canvasBoardId)
        let cardA = CanvasDAL.addWebCard(url: "https://a.example.com", boardId: boardId, x: 0, y: 0, in: context)
        let cardB = CanvasDAL.addWebCard(url: "https://b.example.com", boardId: boardId, x: 100, y: 0, in: context)
        let connector = CanvasDAL.addConnector(from: try #require(cardA.canvasCardId), to: try #require(cardB.canvasCardId), boardId: boardId, in: context)

        CanvasDAL.removeConnector(connector, in: context)

        #expect(connector.isActive == false)
        #expect(CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context).isEmpty)
    }

    // MARK: - seedBoard(fromNeighborhoodOf:) — "Send to Canvas" (Decision 4)

    @Test func seedBoardFromNeighborhoodCreatesACenterCardAndOnePerDirectLinkWithConnectors() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let center = DocumentDAL.create(title: "Center", content: "[[Leaf One]] [[Leaf Two]]", libraryId: libraryId, in: context)
        let leafOne = DocumentDAL.create(title: "Leaf One", content: "[[Leaf Two]]", libraryId: libraryId, in: context)
        let leafTwo = DocumentDAL.create(title: "Leaf Two", content: "", libraryId: libraryId, in: context)

        let board = try #require(CanvasDAL.seedBoard(fromNeighborhoodOf: center, libraryId: libraryId, in: context))

        #expect(board.name == "Center — Map")
        let boardId = try #require(board.canvasBoardId)
        let cards = CanvasDAL.fetchActiveCards(boardId: boardId, in: context)
        #expect(Set(cards.compactMap { $0.documentId }) == Set([center.documentId, leafOne.documentId, leafTwo.documentId].compactMap { $0 }))

        // Center→LeafOne, Center→LeafTwo, and LeafOne→LeafTwo — a link that exists between two
        // non-center members, not just center↔link.
        let connectors = CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context)
        #expect(connectors.count == 3)
    }

    @Test func seedBoardFromNeighborhoodOnADocumentWithZeroLinksCreatesOnlyTheCenterCard() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let lonely = DocumentDAL.create(title: "Lonely", content: "Nothing linked.", libraryId: libraryId, in: context)

        let board = try #require(CanvasDAL.seedBoard(fromNeighborhoodOf: lonely, libraryId: libraryId, in: context))

        let boardId = try #require(board.canvasBoardId)
        let cards = CanvasDAL.fetchActiveCards(boardId: boardId, in: context)
        #expect(cards.count == 1)
        #expect(cards.first?.documentId == lonely.documentId)
        #expect(CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context).isEmpty)
    }

    @Test func seedBoardFromNeighborhoodCreatesANewBoardOnEachInvocation() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "", libraryId: libraryId, in: context)

        let first = try #require(CanvasDAL.seedBoard(fromNeighborhoodOf: document, libraryId: libraryId, in: context))
        let second = try #require(CanvasDAL.seedBoard(fromNeighborhoodOf: document, libraryId: libraryId, in: context))

        #expect(first.canvasBoardId != second.canvasBoardId)
        #expect(CanvasDAL.fetchActiveBoards(libraryId: libraryId, in: context).count == 2)
    }

    // MARK: - seedBoard(fromCluster:)

    @Test func seedBoardFromClusterCreatesACardPerMemberAndConnectorsForInternalLinks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let a = DocumentDAL.create(title: "A", content: "[[B]]", libraryId: libraryId, in: context)
        let b = DocumentDAL.create(title: "B", content: "[[C]]", libraryId: libraryId, in: context)
        let c = DocumentDAL.create(title: "C", content: "", libraryId: libraryId, in: context)
        let cluster = [a, b, c]

        let board = try #require(CanvasDAL.seedBoard(fromCluster: cluster, libraryId: libraryId, in: context))

        let boardId = try #require(board.canvasBoardId)
        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).count == 3)
        #expect(CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context).count == 2)
    }

}
