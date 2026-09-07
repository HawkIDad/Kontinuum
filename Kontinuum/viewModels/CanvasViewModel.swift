// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasViewModel.swift
//  Kontinuum
//

import Foundation
import SwiftData
import Observation

/// Serves both S16 sub-flows — the board list (`CanvasBoardListView`) and a selected board's
/// contents (`CanvasBoardView`) — rather than two view models, the same rationale
/// `TemplateViewModel` already established for its own Picker+Manager split.
@Observable
final class CanvasViewModel {

    private(set) var boards: [CanvasBoard] = []
    private(set) var cards: [CanvasCard] = []
    private(set) var connectors: [CanvasConnector] = []

    let libraryId: UUID
    private let modelContext: ModelContext

    init(libraryId: UUID, modelContext: ModelContext) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        loadBoards()
    }

    // MARK: - Board list

    func loadBoards() {
        boards = CanvasDAL.fetchActiveBoards(libraryId: libraryId, in: modelContext)
    }

    @discardableResult
    func createBoard(name: String) -> CanvasBoard {
        let board = CanvasDAL.createBoard(name: name, libraryId: libraryId, in: modelContext)
        loadBoards()
        return board
    }

    func renameBoard(_ board: CanvasBoard, to name: String) {
        CanvasDAL.renameBoard(board, to: name, in: modelContext)
        loadBoards()
    }

    func deleteBoard(_ board: CanvasBoard) {
        CanvasDAL.deleteBoard(board, in: modelContext)
        loadBoards()
    }

    /// Parses `jsonString` (a picked `.canvas` file's contents) into a new board — `nil` if it
    /// isn't valid JSON Canvas.
    @discardableResult
    func importBoard(named boardName: String, jsonString: String) -> CanvasBoard? {
        let board = CanvasDAL.importJSONCanvas(jsonString, boardName: boardName, libraryId: libraryId, in: modelContext)
        loadBoards()
        return board
    }

    // MARK: - Board contents

    private(set) var board: CanvasBoard?

    func load(_ board: CanvasBoard) {
        self.board = board
        CanvasDAL.reconcileBoundBoard(board, in: modelContext) // no-op if unbound (Decision 12: appear-triggered, never a timer)
        loadCards()
        loadConnectors()
    }

    // MARK: - Bidirectional Graph ↔ Canvas Binding (C5)

    func bind(_ board: CanvasBoard, to document: Document) {
        CanvasDAL.bind(board, to: document, in: modelContext)
        if self.board?.canvasBoardId == board.canvasBoardId {
            loadCards()
            loadConnectors()
        }
    }

    func unbind(_ board: CanvasBoard) {
        CanvasDAL.unbind(board, in: modelContext)
    }

    func boundDocumentTitle(for board: CanvasBoard) -> String? {
        guard let boundDocumentId = board.boundDocumentId,
              let document = Document.fetch(syncId: boundDocumentId, in: modelContext)
        else { return nil }
        return document.title?.isEmpty == false ? document.title : "Untitled"
    }

    /// Re-runs `load(_:)` (reconcile + reload cards/connectors) against the currently loaded
    /// board — used after Canvas's own connector-creates-link flow (C6) writes a new `[[link]]`
    /// into a member document, so the new connector appears without waiting for the next appear.
    func reload() {
        guard let board else { return }
        load(board)
    }

    func loadCards() {
        guard let boardId = board?.canvasBoardId else { return }
        cards = CanvasDAL.fetchActiveCards(boardId: boardId, in: modelContext)
    }

    func loadConnectors() {
        guard let boardId = board?.canvasBoardId else { return }
        connectors = CanvasDAL.fetchActiveConnectors(boardId: boardId, in: modelContext)
    }

    func addNoteCard(documentId: UUID, x: Double, y: Double) {
        guard let boardId = board?.canvasBoardId else { return }
        CanvasDAL.addNoteCard(documentId: documentId, boardId: boardId, x: x, y: y, in: modelContext)
        loadCards()
    }

    func addMediaCard(attachmentId: UUID, x: Double, y: Double) {
        guard let boardId = board?.canvasBoardId else { return }
        CanvasDAL.addMediaCard(attachmentId: attachmentId, boardId: boardId, x: x, y: y, in: modelContext)
        loadCards()
    }

    func addWebCard(url: String, x: Double, y: Double) {
        guard let boardId = board?.canvasBoardId else { return }
        CanvasDAL.addWebCard(url: url, boardId: boardId, x: x, y: y, in: modelContext)
        loadCards()
    }

    func addGroupCard(label: String, x: Double, y: Double) {
        guard let boardId = board?.canvasBoardId else { return }
        CanvasDAL.addGroupCard(label: label, boardId: boardId, x: x, y: y, in: modelContext)
        loadCards()
    }

    func moveCard(_ card: CanvasCard, x: Double, y: Double) {
        CanvasDAL.moveCard(card, x: x, y: y, in: modelContext)
        loadCards()
    }

    func resizeCard(_ card: CanvasCard, width: Double, height: Double) {
        CanvasDAL.resizeCard(card, width: width, height: height, in: modelContext)
        loadCards()
    }

    func removeCard(_ card: CanvasCard) {
        CanvasDAL.removeCard(card, in: modelContext)
        loadCards()
        loadConnectors()
    }

    func addConnector(from fromCard: CanvasCard, to toCard: CanvasCard, label: String? = nil) {
        guard let boardId = board?.canvasBoardId, let fromCardId = fromCard.canvasCardId, let toCardId = toCard.canvasCardId else { return }
        CanvasDAL.addConnector(from: fromCardId, to: toCardId, boardId: boardId, label: label, in: modelContext)
        loadConnectors()
    }

    func removeConnector(_ connector: CanvasConnector) {
        CanvasDAL.removeConnector(connector, in: modelContext)
        loadConnectors()
    }

    /// Every Document in the library, fuzzy-filtered by `query` — reuses
    /// `WikilinkParser.fuzzyMatches`, the same function `DocumentViewModel.wikilinkSuggestions`
    /// already calls, rather than a second fuzzy-match implementation.
    func noteCardCandidates(matching query: String, limit: Int = 20) -> [Document] {
        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: modelContext)
        guard !query.isEmpty else { return Array(documents.prefix(limit)) }
        return Array(documents.filter { WikilinkParser.fuzzyMatches($0.title ?? "", query: query) }.prefix(limit))
    }

    /// Every Attachment across the library — the Canvas media-card picker browses by document
    /// title (grouped) rather than a flat attachment list, so the view pairs each with its
    /// owning document via `DocumentDAL.fetch`.
    func mediaCardCandidates() -> [Attachment] {
        AttachmentDAL.fetchActive(libraryId: libraryId, in: modelContext)
    }

    func exportJSON() -> String? {
        guard let board else { return nil }
        return CanvasDAL.exportJSONCanvas(board: board, in: modelContext)
    }

}
