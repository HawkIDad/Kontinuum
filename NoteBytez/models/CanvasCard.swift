// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasCard.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// A card's content source — exactly one of `CanvasCard`'s `documentId`/`attachmentId`/`url` is
/// populated depending on this, mirroring JSON Canvas's `file`/`file`/`link`/`group` node types
/// (`.note`/`.media` both map to a `file` node on export, distinguished by which reference field
/// is set). Stored as a plain `String` for CloudKit safety, same convention as
/// `PropertyValueType`.
enum CanvasCardType: String, Codable, CaseIterable {
    case note
    case media
    case web
    case group
}

/// One card on a `CanvasBoard` — an owned child, no `libraryId` of its own, same shape as
/// `Block` (`BlockDAL`'s library-wide fetch joins through `Document` for the same reason
/// `CanvasDAL` would join through `CanvasBoard` if a library-wide card fetch were ever needed).
@Model
final class CanvasCard: Codable, Identifiable {

    var canvasBoardId: UUID?
    var cardType: String?
    var documentId: UUID?
    var attachmentId: UUID?
    var url: String?
    /// Group title only — JSON Canvas has no title field on `file`/`link` nodes, only `group`.
    var label: String?
    var positionX: Double?
    var positionY: Double?
    var width: Double?
    var height: Double?
    /// JSON Canvas's optional node color (a preset "1"-"6" or a hex string), stored verbatim.
    var color: String?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var canvasCardId: UUID? = UUID()
    var id: UUID { return self.canvasCardId! }

    init(canvasBoardId: UUID, cardType: CanvasCardType, positionX: Double, positionY: Double, width: Double, height: Double) {
        self.canvasBoardId = canvasBoardId
        self.cardType = cardType.rawValue
        self.positionX = positionX
        self.positionY = positionY
        self.width = width
        self.height = height
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.canvasCardId = UUID()
    }

    var canvasCardType: CanvasCardType? {
        cardType.flatMap(CanvasCardType.init)
    }

    enum CodingKeys: String, CodingKey {
        case canvasBoardId, cardType, documentId, attachmentId, url, label, positionX, positionY, width, height, color, createdOn, createdBy, updatedOn, updatedBy, isActive, canvasCardId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            canvasBoardId: try container.decodeIfPresent(UUID.self, forKey: .canvasBoardId) ?? UUID(),
            cardType: (try container.decodeIfPresent(String.self, forKey: .cardType)).flatMap(CanvasCardType.init) ?? .note,
            positionX: try container.decodeIfPresent(Double.self, forKey: .positionX) ?? 0,
            positionY: try container.decodeIfPresent(Double.self, forKey: .positionY) ?? 0,
            width: try container.decodeIfPresent(Double.self, forKey: .width) ?? 0,
            height: try container.decodeIfPresent(Double.self, forKey: .height) ?? 0
        )
        self.documentId = try container.decodeIfPresent(UUID.self, forKey: .documentId)
        self.attachmentId = try container.decodeIfPresent(UUID.self, forKey: .attachmentId)
        self.url = try container.decodeIfPresent(String.self, forKey: .url)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        self.color = try container.decodeIfPresent(String.self, forKey: .color)
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.canvasCardId = try container.decodeIfPresent(UUID.self, forKey: .canvasCardId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.canvasBoardId, forKey: .canvasBoardId)
        try container.encode(self.cardType, forKey: .cardType)
        try container.encode(self.documentId, forKey: .documentId)
        try container.encode(self.attachmentId, forKey: .attachmentId)
        try container.encode(self.url, forKey: .url)
        try container.encode(self.label, forKey: .label)
        try container.encode(self.positionX, forKey: .positionX)
        try container.encode(self.positionY, forKey: .positionY)
        try container.encode(self.width, forKey: .width)
        try container.encode(self.height, forKey: .height)
        try container.encode(self.color, forKey: .color)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.canvasCardId, forKey: .canvasCardId)
    }

}
