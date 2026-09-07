// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

enum CanvasDAL {

    static let defaultCardWidth: Double = 240
    static let defaultCardHeight: Double = 140
    static let defaultGroupWidth: Double = 320
    static let defaultGroupHeight: Double = 240

    // MARK: - Board CRUD

    static func createBoard(name: String, libraryId: UUID, in context: ModelContext) -> CanvasBoard {
        let board = CanvasBoard(name: name, libraryId: libraryId)
        context.insert(board)
        SyncEngine.shared.recordChanged(board, in: context)
        return board
    }

    static func fetchActiveBoards(libraryId: UUID, in context: ModelContext) -> [CanvasBoard] {
        let predicate = #Predicate<CanvasBoard> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<CanvasBoard>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Every active board bound to `documentId` — `DocumentViewModel.save()`'s reconciliation
    /// trigger (C4) uses this to guard the call: a document with no bound board does no extra
    /// work at all on save.
    static func fetchBoundBoards(boundTo documentId: UUID, in context: ModelContext) -> [CanvasBoard] {
        let predicate = #Predicate<CanvasBoard> { $0.boundDocumentId == documentId && $0.isActive == true }
        return (try? context.fetch(FetchDescriptor<CanvasBoard>(predicate: predicate))) ?? []
    }

    static func renameBoard(_ board: CanvasBoard, to name: String, in context: ModelContext) {
        board.name = name
        board.updatedOn = Date()
        SyncEngine.shared.recordChanged(board, in: context)
    }

    /// Soft-deletes the board and every card/connector on it — a board with no surviving
    /// definition shouldn't leave orphaned cards/connectors behind, mirrors
    /// `TemplateDAL.deleteGroup`'s cascade.
    static func deleteBoard(_ board: CanvasBoard, in context: ModelContext) {
        guard let boardId = board.canvasBoardId else { return }

        for card in fetchActiveCards(boardId: boardId, in: context) {
            removeCard(card, in: context)
        }
        for connector in fetchActiveConnectors(boardId: boardId, in: context) {
            removeConnector(connector, in: context)
        }

        board.isActive = false
        board.updatedOn = Date()
        SyncEngine.shared.recordChanged(board, in: context)
    }

    // MARK: - Card CRUD

    static func fetchActiveCards(boardId: UUID, in context: ModelContext) -> [CanvasCard] {
        let predicate = #Predicate<CanvasCard> { $0.canvasBoardId == boardId && $0.isActive == true }
        return (try? context.fetch(FetchDescriptor<CanvasCard>(predicate: predicate))) ?? []
    }

    @discardableResult
    static func addNoteCard(documentId: UUID, boardId: UUID, x: Double, y: Double, in context: ModelContext) -> CanvasCard {
        let card = CanvasCard(canvasBoardId: boardId, cardType: .note, positionX: x, positionY: y, width: defaultCardWidth, height: defaultCardHeight)
        card.documentId = documentId
        context.insert(card)
        SyncEngine.shared.recordChanged(card, in: context)
        return card
    }

    @discardableResult
    static func addMediaCard(attachmentId: UUID, boardId: UUID, x: Double, y: Double, in context: ModelContext) -> CanvasCard {
        let card = CanvasCard(canvasBoardId: boardId, cardType: .media, positionX: x, positionY: y, width: defaultCardWidth, height: defaultCardHeight)
        card.attachmentId = attachmentId
        context.insert(card)
        SyncEngine.shared.recordChanged(card, in: context)
        return card
    }

    @discardableResult
    static func addWebCard(url: String, boardId: UUID, x: Double, y: Double, in context: ModelContext) -> CanvasCard {
        let card = CanvasCard(canvasBoardId: boardId, cardType: .web, positionX: x, positionY: y, width: defaultCardWidth, height: defaultCardHeight)
        card.url = url
        context.insert(card)
        SyncEngine.shared.recordChanged(card, in: context)
        return card
    }

    @discardableResult
    static func addGroupCard(label: String, boardId: UUID, x: Double, y: Double, in context: ModelContext) -> CanvasCard {
        let card = CanvasCard(canvasBoardId: boardId, cardType: .group, positionX: x, positionY: y, width: defaultGroupWidth, height: defaultGroupHeight)
        card.label = label
        context.insert(card)
        SyncEngine.shared.recordChanged(card, in: context)
        return card
    }

    static func moveCard(_ card: CanvasCard, x: Double, y: Double, in context: ModelContext) {
        card.positionX = x
        card.positionY = y
        card.updatedOn = Date()
        SyncEngine.shared.recordChanged(card, in: context)
    }

    static func resizeCard(_ card: CanvasCard, width: Double, height: Double, in context: ModelContext) {
        card.width = max(width, 60)
        card.height = max(height, 40)
        card.updatedOn = Date()
        SyncEngine.shared.recordChanged(card, in: context)
    }

    /// Soft-deletes the card and every connector touching it — a dangling connector referencing
    /// a removed card would have nothing to draw between.
    static func removeCard(_ card: CanvasCard, in context: ModelContext) {
        guard let cardId = card.canvasCardId, let boardId = card.canvasBoardId else { return }

        let touching = fetchActiveConnectors(boardId: boardId, in: context).filter { $0.fromCardId == cardId || $0.toCardId == cardId }
        for connector in touching {
            removeConnector(connector, in: context)
        }

        card.isActive = false
        card.updatedOn = Date()
        SyncEngine.shared.recordChanged(card, in: context)
    }

    // MARK: - Connector CRUD

    static func fetchActiveConnectors(boardId: UUID, in context: ModelContext) -> [CanvasConnector] {
        let predicate = #Predicate<CanvasConnector> { $0.canvasBoardId == boardId && $0.isActive == true }
        return (try? context.fetch(FetchDescriptor<CanvasConnector>(predicate: predicate))) ?? []
    }

    @discardableResult
    static func addConnector(from fromCardId: UUID, to toCardId: UUID, boardId: UUID, fromSide: String? = nil, toSide: String? = nil, color: String? = nil, label: String? = nil, in context: ModelContext) -> CanvasConnector {
        let connector = CanvasConnector(canvasBoardId: boardId, fromCardId: fromCardId, toCardId: toCardId)
        connector.fromSide = fromSide
        connector.toSide = toSide
        connector.color = color
        connector.label = label
        context.insert(connector)
        SyncEngine.shared.recordChanged(connector, in: context)
        return connector
    }

    static func removeConnector(_ connector: CanvasConnector, in context: ModelContext) {
        connector.isActive = false
        connector.updatedOn = Date()
        SyncEngine.shared.recordChanged(connector, in: context)
    }

    // MARK: - JSON Canvas export

    /// `.note`/`.media` cards → `file` nodes (path = `ExportDAL`'s own title-to-filename
    /// convention for a note, the attachment's own `fileName` for media — so a paired full
    /// library export lands these references correctly); `.web` → `link` node; `.group` →
    /// `group` node. A card whose reference no longer resolves (a soft-deleted Document/
    /// Attachment) is skipped rather than exporting a broken path.
    static func exportJSONCanvas(board: CanvasBoard, in context: ModelContext) -> String {
        guard let boardId = board.canvasBoardId else { return "{\"nodes\":[],\"edges\":[]}" }

        let cards = fetchActiveCards(boardId: boardId, in: context)
        var nodes: [JSONCanvasNode] = []

        for card in cards {
            guard let cardId = card.canvasCardId, let cardType = card.canvasCardType else { continue }
            let id = cardId.uuidString
            let x = card.positionX ?? 0
            let y = card.positionY ?? 0
            let width = card.width ?? defaultCardWidth
            let height = card.height ?? defaultCardHeight

            switch cardType {
            case .note:
                guard let documentId = card.documentId, let document = Document.fetch(syncId: documentId, in: context) else { continue }
                let file = ExportDAL.sanitizedFilename(for: document.title ?? "Untitled") + ".md"
                nodes.append(JSONCanvasNode(id: id, type: .file, x: x, y: y, width: width, height: height, color: card.color, file: file))
            case .media:
                guard let attachmentId = card.attachmentId, let attachment = Attachment.fetch(syncId: attachmentId, in: context), let fileName = attachment.fileName else { continue }
                nodes.append(JSONCanvasNode(id: id, type: .file, x: x, y: y, width: width, height: height, color: card.color, file: fileName))
            case .web:
                guard let url = card.url else { continue }
                nodes.append(JSONCanvasNode(id: id, type: .link, x: x, y: y, width: width, height: height, color: card.color, url: url))
            case .group:
                nodes.append(JSONCanvasNode(id: id, type: .group, x: x, y: y, width: width, height: height, color: card.color, label: card.label))
            }
        }

        let cardIdByCardId = Dictionary(uniqueKeysWithValues: cards.compactMap { card -> (UUID, String)? in
            guard let cardId = card.canvasCardId else { return nil }
            return (cardId, cardId.uuidString)
        })

        let edges: [JSONCanvasEdge] = fetchActiveConnectors(boardId: boardId, in: context).compactMap { connector in
            guard let connectorId = connector.canvasConnectorId,
                  let fromCardId = connector.fromCardId, let fromNode = cardIdByCardId[fromCardId],
                  let toCardId = connector.toCardId, let toNode = cardIdByCardId[toCardId] else { return nil }
            return JSONCanvasEdge(id: connectorId.uuidString, fromNode: fromNode, fromSide: connector.fromSide, toNode: toNode, toSide: connector.toSide, color: connector.color, label: connector.label)
        }

        let document = JSONCanvasDocument(nodes: nodes, edges: edges)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(document), let json = String(data: data, encoding: .utf8) else {
            return "{\"nodes\":[],\"edges\":[]}"
        }
        return json
    }

    // MARK: - JSON Canvas import

    /// Creates a new `CanvasBoard` named `boardName` from a `.canvas` file's JSON text. A `file`/
    /// `link` node resolves against the library's *existing* Documents (by exported filename) or
    /// Attachments (by filename) — an unresolved reference is dropped, the rest of the board
    /// still imports. A `text` node becomes a new `Document` (see Phase 9's Context note) and a
    /// `.note` card referencing it. Returns `nil` if `jsonString` isn't valid JSON Canvas.
    static func importJSONCanvas(_ jsonString: String, boardName: String, libraryId: UUID, in context: ModelContext) -> CanvasBoard? {
        guard let data = jsonString.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(JSONCanvasDocument.self, from: data) else {
            return nil
        }

        let board = createBoard(name: boardName, libraryId: libraryId, in: context)
        guard let boardId = board.canvasBoardId else { return board }

        let existingDocuments = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        let existingAttachments = AttachmentDAL.fetchActive(libraryId: libraryId, in: context)

        var cardIdByNodeId: [String: UUID] = [:]

        for node in parsed.nodes {
            let card: CanvasCard?
            switch node.type {
            case .file:
                guard let file = node.file else { card = nil; break }
                let baseName = (file as NSString).lastPathComponent
                if baseName.hasSuffix(".md"), let match = existingDocuments.first(where: { ExportDAL.sanitizedFilename(for: $0.title ?? "Untitled") + ".md" == baseName }), let documentId = match.documentId {
                    card = CanvasCard(canvasBoardId: boardId, cardType: .note, positionX: node.x, positionY: node.y, width: node.width, height: node.height)
                    card?.documentId = documentId
                } else if let match = existingAttachments.first(where: { $0.fileName == baseName }), let attachmentId = match.attachmentId {
                    card = CanvasCard(canvasBoardId: boardId, cardType: .media, positionX: node.x, positionY: node.y, width: node.width, height: node.height)
                    card?.attachmentId = attachmentId
                } else {
                    card = nil
                }
            case .link:
                guard let url = node.url else { card = nil; break }
                card = CanvasCard(canvasBoardId: boardId, cardType: .web, positionX: node.x, positionY: node.y, width: node.width, height: node.height)
                card?.url = url
            case .group:
                card = CanvasCard(canvasBoardId: boardId, cardType: .group, positionX: node.x, positionY: node.y, width: node.width, height: node.height)
                card?.label = node.label
            case .text:
                let created = DocumentDAL.create(title: (node.text ?? "").components(separatedBy: .newlines).first ?? "Untitled", content: node.text ?? "", libraryId: libraryId, in: context)
                card = CanvasCard(canvasBoardId: boardId, cardType: .note, positionX: node.x, positionY: node.y, width: node.width, height: node.height)
                card?.documentId = created.documentId
            }

            guard let card else { continue }
            card.color = node.color
            context.insert(card)
            SyncEngine.shared.recordChanged(card, in: context)
            if let cardId = card.canvasCardId { cardIdByNodeId[node.id] = cardId }
        }

        for edge in parsed.edges {
            guard let fromCardId = cardIdByNodeId[edge.fromNode], let toCardId = cardIdByNodeId[edge.toNode] else { continue }
            addConnector(from: fromCardId, to: toCardId, boardId: boardId, fromSide: edge.fromSide, toSide: edge.toSide, color: edge.color, label: edge.label, in: context)
        }

        return board
    }

    // MARK: - "Send to Canvas" (Decision 4)

    private static let neighborhoodRadius: Double = 320

    /// One-time, one-directional seed (no dedupe, no live binding back to the graph — Decision
    /// 4): a new board named "<Title> — Map" with the center document at the origin, its direct
    /// links (`GraphDAL.directLinks`) laid out radially around it, and a `CanvasConnector` for
    /// every `[[link]]` that exists between *any two* of those documents, not just center↔link.
    @discardableResult
    static func seedBoard(fromNeighborhoodOf document: Document, libraryId: UUID, in context: ModelContext) -> CanvasBoard? {
        guard document.documentId != nil else { return nil }
        let neighbors = GraphDAL.directLinks(for: document, libraryId: libraryId, in: context)
        let title = document.title ?? "Untitled"
        let board = createBoard(name: "\(title) — Map", libraryId: libraryId, in: context)
        guard let boardId = board.canvasBoardId else { return board }

        var members = [document]
        members.append(contentsOf: neighbors)

        var positions: [(x: Double, y: Double)] = [(x: 0, y: 0)]
        positions.append(contentsOf: RadialLayout.points(count: neighbors.count, radius: neighborhoodRadius))

        seedCardsAndConnectors(members: members, positions: positions, boardId: boardId, in: context)
        return board
    }

    /// Same shape as `seedBoard(fromNeighborhoodOf:...)`, seeded from a
    /// `GraphInsightsDAL.clusters` component instead of one document's direct neighborhood: all
    /// members as cards (grid/circle layout, no meaningful "center"), all internal links as
    /// connectors.
    @discardableResult
    static func seedBoard(fromCluster members: [Document], libraryId: UUID, in context: ModelContext) -> CanvasBoard? {
        guard !members.isEmpty else { return nil }
        let headline = members.first?.title ?? "Cluster"
        let board = createBoard(name: "\(headline) — Map", libraryId: libraryId, in: context)
        guard let boardId = board.canvasBoardId else { return board }

        let positions = RadialLayout.points(count: members.count, radius: neighborhoodRadius)
        seedCardsAndConnectors(members: members, positions: positions, boardId: boardId, in: context)
        return board
    }

    /// Shared by both seed entry points: one `.note` card per member at its given position, then
    /// one connector per `[[link]]` found in any member's content that resolves to another
    /// member (both directions counted independently, since each is a distinct wikilink
    /// occurrence in the source text).
    private static func seedCardsAndConnectors(members: [Document], positions: [(x: Double, y: Double)], boardId: UUID, in context: ModelContext) {
        var cardsByDocumentId: [UUID: CanvasCard] = [:]
        for (member, position) in zip(members, positions) {
            guard let memberId = member.documentId else { continue }
            cardsByDocumentId[memberId] = addNoteCard(documentId: memberId, boardId: boardId, x: position.x, y: position.y, in: context)
        }

        let membersByLowercasedTitle = Dictionary(members.compactMap { member -> (String, Document)? in
            guard let title = member.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return (title.lowercased(), member)
        }, uniquingKeysWith: { first, _ in first })

        for member in members {
            guard let memberId = member.documentId, let fromCardId = cardsByDocumentId[memberId]?.canvasCardId else { continue }
            for linkedTitle in WikilinkParser.extractTitles(from: member.content ?? "") {
                guard let target = membersByLowercasedTitle[linkedTitle.lowercased()],
                      let targetId = target.documentId, targetId != memberId,
                      let toCardId = cardsByDocumentId[targetId]?.canvasCardId
                else { continue }
                addConnector(from: fromCardId, to: toCardId, boardId: boardId, in: context)
            }
        }
    }

    // MARK: - Bidirectional Graph ↔ Canvas Binding (Decision 9(a)/10/11/12)

    /// Binds `board` to `document`'s direct-link neighborhood (fixed at 1 hop, Decision 10) and
    /// seeds it immediately — same shape as `seedBoard(fromNeighborhoodOf:)`'s initial layout,
    /// but reconciled going forward rather than one-shot.
    static func bind(_ board: CanvasBoard, to document: Document, in context: ModelContext) {
        board.boundDocumentId = document.documentId
        board.updatedOn = Date()
        SyncEngine.shared.recordChanged(board, in: context)
        reconcileBoundBoard(board, in: context)
    }

    static func unbind(_ board: CanvasBoard, in context: ModelContext) {
        board.boundDocumentId = nil
        board.updatedOn = Date()
        SyncEngine.shared.recordChanged(board, in: context)
    }

    /// C7's "Open this note as a bound canvas": reuses `document`'s existing bound board if one
    /// already exists, otherwise creates and binds a fresh one — never a second bound board for
    /// the same document.
    @discardableResult
    static func boundBoard(for document: Document, libraryId: UUID, in context: ModelContext) -> CanvasBoard? {
        guard let documentId = document.documentId else { return nil }
        if let existing = fetchBoundBoards(boundTo: documentId, in: context).first {
            return existing
        }
        let board = createBoard(name: "\(document.title ?? "Untitled") — Bound", libraryId: libraryId, in: context)
        bind(board, to: document, in: context)
        return board
    }

    /// Diffs the bound document's current direct-link neighborhood against the board's existing
    /// `.note` cards: adds a card for a newly-linked document, removes a card (and its
    /// connectors, via `removeCard`'s existing cascade) for a document no longer linked. Never
    /// touches a non-`.note` card (web/media/group) or an existing note card's position —
    /// user-placed content and layout survive every reconciliation (Decision 9(a)'s
    /// "read-mostly": links flow into the canvas, never the reverse).
    ///
    /// No-op if `board` isn't bound. Called on `CanvasBoardView` appear and from the bound
    /// document's own save path — never on a timer (Decision 12).
    static func reconcileBoundBoard(_ board: CanvasBoard, in context: ModelContext) {
        guard let boardId = board.canvasBoardId,
              let boundDocumentId = board.boundDocumentId,
              let libraryId = board.libraryId,
              let sourceDocument = Document.fetch(syncId: boundDocumentId, in: context)
        else { return }

        let neighbors = GraphDAL.directLinks(for: sourceDocument, libraryId: libraryId, in: context)
        var members = [sourceDocument]
        members.append(contentsOf: neighbors)
        let desiredDocumentIds = Set(members.compactMap { $0.documentId })

        let existingCards = fetchActiveCards(boardId: boardId, in: context)
        let existingNoteCardsByDocumentId = Dictionary(uniqueKeysWithValues: existingCards.compactMap { card -> (UUID, CanvasCard)? in
            guard card.canvasCardType == .note, let docId = card.documentId else { return nil }
            return (docId, card)
        })

        for (documentId, card) in existingNoteCardsByDocumentId where !desiredDocumentIds.contains(documentId) {
            removeCard(card, in: context)
        }

        let newMembers = members.filter { member in
            guard let id = member.documentId else { return false }
            return existingNoteCardsByDocumentId[id] == nil
        }
        if !newMembers.isEmpty {
            let positions: [(x: Double, y: Double)]
            if existingNoteCardsByDocumentId[boundDocumentId] == nil {
                // First seed: focus at the origin, neighbors radial around it (matches
                // seedBoard's initial layout).
                positions = [(x: 0, y: 0)] + RadialLayout.points(count: newMembers.count - 1, radius: neighborhoodRadius)
            } else {
                positions = RadialLayout.points(count: newMembers.count, radius: neighborhoodRadius)
            }
            for (member, position) in zip(newMembers, positions) {
                guard let memberId = member.documentId else { continue }
                addNoteCard(documentId: memberId, boardId: boardId, x: position.x, y: position.y, in: context)
            }
        }

        reconcileLinkMirroringConnectors(members: members, boardId: boardId, in: context)
    }

    /// Adds/removes connectors strictly between two `.note` cards that are both current
    /// neighborhood members, to exactly match the `[[link]]`s between them — a connector
    /// touching any non-note card, or a note card outside the neighborhood, is never inspected.
    /// On a bound board every note-to-note connector is expected to correspond to a real link by
    /// construction (Decision 9(a): drawing one always goes through the confirm-to-create-link
    /// flow), so this can safely own that whole subset without extra "who drew this" bookkeeping.
    private static func reconcileLinkMirroringConnectors(members: [Document], boardId: UUID, in context: ModelContext) {
        let noteCards = fetchActiveCards(boardId: boardId, in: context).filter { $0.canvasCardType == .note }
        let cardByDocumentId = Dictionary(uniqueKeysWithValues: noteCards.compactMap { card -> (UUID, CanvasCard)? in
            guard let docId = card.documentId else { return nil }
            return (docId, card)
        })
        let noteCardIds = Set(noteCards.compactMap { $0.canvasCardId })

        let membersByLowercasedTitle = Dictionary(members.compactMap { member -> (String, Document)? in
            guard let title = member.title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return (title.lowercased(), member)
        }, uniquingKeysWith: { first, _ in first })

        func pairKey(_ a: UUID, _ b: UUID) -> String {
            [a.uuidString, b.uuidString].sorted().joined(separator: "|")
        }

        var desiredPairKeys: Set<String> = []
        for member in members {
            guard let memberId = member.documentId, let fromCardId = cardByDocumentId[memberId]?.canvasCardId else { continue }
            for linkedTitle in WikilinkParser.extractTitles(from: member.content ?? "") {
                guard let target = membersByLowercasedTitle[linkedTitle.lowercased()],
                      let targetId = target.documentId, targetId != memberId,
                      let toCardId = cardByDocumentId[targetId]?.canvasCardId
                else { continue }
                desiredPairKeys.insert(pairKey(fromCardId, toCardId))
            }
        }

        var connectorByPairKey: [String: CanvasConnector] = [:]
        for connector in fetchActiveConnectors(boardId: boardId, in: context) {
            guard let from = connector.fromCardId, let to = connector.toCardId,
                  noteCardIds.contains(from), noteCardIds.contains(to)
            else { continue }
            connectorByPairKey[pairKey(from, to)] = connector
        }

        for (key, connector) in connectorByPairKey where !desiredPairKeys.contains(key) {
            removeConnector(connector, in: context)
        }

        for member in members {
            guard let memberId = member.documentId, let fromCardId = cardByDocumentId[memberId]?.canvasCardId else { continue }
            for linkedTitle in WikilinkParser.extractTitles(from: member.content ?? "") {
                guard let target = membersByLowercasedTitle[linkedTitle.lowercased()],
                      let targetId = target.documentId, targetId != memberId,
                      let toCardId = cardByDocumentId[targetId]?.canvasCardId
                else { continue }
                let key = pairKey(fromCardId, toCardId)
                guard connectorByPairKey[key] == nil else { continue }
                let newConnector = addConnector(from: fromCardId, to: toCardId, boardId: boardId, in: context)
                connectorByPairKey[key] = newConnector
            }
        }
    }

}
