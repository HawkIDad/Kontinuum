// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasConnector.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// A labeled line between two `CanvasCard`s — an owned child of `CanvasBoard`, mirrors
/// `CanvasCard`'s no-`libraryId` shape. `fromSide`/`toSide` mirror JSON Canvas edges exactly;
/// `fromEnd`/`toEnd` (arrowhead style) are not modeled — a deliberate, stated scope cut, see
/// NoteBytez-R1-Implementation.md Phase 9.
@Model
final class CanvasConnector: Codable, Identifiable {

    var canvasBoardId: UUID?
    var fromCardId: UUID?
    var toCardId: UUID?
    var fromSide: String?
    var toSide: String?
    var color: String?
    var label: String?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var canvasConnectorId: UUID? = UUID()
    var id: UUID { return self.canvasConnectorId! }

    init(canvasBoardId: UUID, fromCardId: UUID, toCardId: UUID) {
        self.canvasBoardId = canvasBoardId
        self.fromCardId = fromCardId
        self.toCardId = toCardId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.canvasConnectorId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case canvasBoardId, fromCardId, toCardId, fromSide, toSide, color, label, createdOn, createdBy, updatedOn, updatedBy, isActive, canvasConnectorId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            canvasBoardId: try container.decodeIfPresent(UUID.self, forKey: .canvasBoardId) ?? UUID(),
            fromCardId: try container.decodeIfPresent(UUID.self, forKey: .fromCardId) ?? UUID(),
            toCardId: try container.decodeIfPresent(UUID.self, forKey: .toCardId) ?? UUID()
        )
        self.fromSide = try container.decodeIfPresent(String.self, forKey: .fromSide)
        self.toSide = try container.decodeIfPresent(String.self, forKey: .toSide)
        self.color = try container.decodeIfPresent(String.self, forKey: .color)
        self.label = try container.decodeIfPresent(String.self, forKey: .label)
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.canvasConnectorId = try container.decodeIfPresent(UUID.self, forKey: .canvasConnectorId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.canvasBoardId, forKey: .canvasBoardId)
        try container.encode(self.fromCardId, forKey: .fromCardId)
        try container.encode(self.toCardId, forKey: .toCardId)
        try container.encode(self.fromSide, forKey: .fromSide)
        try container.encode(self.toSide, forKey: .toSide)
        try container.encode(self.color, forKey: .color)
        try container.encode(self.label, forKey: .label)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.canvasConnectorId, forKey: .canvasConnectorId)
    }

}
