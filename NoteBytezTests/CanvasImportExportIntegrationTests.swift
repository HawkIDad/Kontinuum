// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasImportExportIntegrationTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

/// The "JSON Canvas import/export round-trip fidelity" task from
/// NoteBytez-R1-Implementation.md Phase 9 — one of each card type plus a labeled connector,
/// exported then re-imported into a fresh board within the same library (so every `file`/`link`
/// reference actually resolves), asserting the reconstituted board matches.
struct CanvasImportExportIntegrationTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Attachment.self, CanvasBoard.self, CanvasCard.self, CanvasConnector.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func exportingThenReimportingABoardReconstitutesEveryCardTypeAndAConnector() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let document = DocumentDAL.create(title: "Suspect A", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let attachment = Attachment(documentId: documentId, fileName: "harbor.jpg", relativePath: "AttachmentStore/\(documentId.uuidString)/1-harbor.jpg", mimeType: "image/jpeg")
        context.insert(attachment)
        let attachmentId = try #require(attachment.attachmentId)

        let board = CanvasDAL.createBoard(name: "Mystery Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)

        let noteCard = CanvasDAL.addNoteCard(documentId: documentId, boardId: boardId, x: 10, y: 20, in: context)
        CanvasDAL.addMediaCard(attachmentId: attachmentId, boardId: boardId, x: 300, y: 20, in: context)
        let webCard = CanvasDAL.addWebCard(url: "https://example.com/reference", boardId: boardId, x: 10, y: 300, in: context)
        CanvasDAL.addGroupCard(label: "Suspects", boardId: boardId, x: 500, y: 20, in: context)
        CanvasDAL.addConnector(from: try #require(noteCard.canvasCardId), to: try #require(webCard.canvasCardId), boardId: boardId, label: "reveals", in: context)

        let json = CanvasDAL.exportJSONCanvas(board: board, in: context)

        let reimported = try #require(CanvasDAL.importJSONCanvas(json, boardName: "Reimported", libraryId: libraryId, in: context))
        let reimportedBoardId = try #require(reimported.canvasBoardId)

        let cards = CanvasDAL.fetchActiveCards(boardId: reimportedBoardId, in: context)
        #expect(cards.count == 4)

        let reimportedNote = cards.first { $0.canvasCardType == .note }
        #expect(reimportedNote?.documentId == documentId)

        let reimportedMedia = cards.first { $0.canvasCardType == .media }
        #expect(reimportedMedia?.attachmentId == attachmentId)

        let reimportedWeb = cards.first { $0.canvasCardType == .web }
        #expect(reimportedWeb?.url == "https://example.com/reference")

        let reimportedGroup = cards.first { $0.canvasCardType == .group }
        #expect(reimportedGroup?.label == "Suspects")

        let connectors = CanvasDAL.fetchActiveConnectors(boardId: reimportedBoardId, in: context)
        #expect(connectors.count == 1)
        #expect(connectors.first?.label == "reveals")
        #expect(connectors.first?.fromCardId == reimportedNote?.canvasCardId)
        #expect(connectors.first?.toCardId == reimportedWeb?.canvasCardId)
    }

    @Test func importingAnUnresolvableFileReferenceIsDroppedNotAHardFailure() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let json = """
        {"nodes":[{"id":"1","type":"file","x":0,"y":0,"width":100,"height":100,"file":"Nonexistent.md"}],"edges":[]}
        """

        let board = try #require(CanvasDAL.importJSONCanvas(json, boardName: "Board", libraryId: libraryId, in: context))
        let boardId = try #require(board.canvasBoardId)

        #expect(CanvasDAL.fetchActiveCards(boardId: boardId, in: context).isEmpty)
    }

    @Test func importingATextNodeCreatesANewDocumentAndANoteCard() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let json = """
        {"nodes":[{"id":"1","type":"text","x":0,"y":0,"width":100,"height":100,"text":"A freeform idea"}],"edges":[]}
        """

        let board = try #require(CanvasDAL.importJSONCanvas(json, boardName: "Board", libraryId: libraryId, in: context))
        let boardId = try #require(board.canvasBoardId)

        let cards = CanvasDAL.fetchActiveCards(boardId: boardId, in: context)
        #expect(cards.count == 1)
        #expect(cards.first?.canvasCardType == .note)

        let documentId = try #require(cards.first?.documentId)
        let document = try #require(Document.fetch(syncId: documentId, in: context))
        #expect(document.content == "A freeform idea")
    }

}
