// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasBoard.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// A named, library-scoped canvas — same shape as `Notebook` (name + `libraryId` + audit,
/// nothing else). Owns `CanvasCard`/`CanvasConnector` rows via `canvasBoardId`.
@Model
final class CanvasBoard: Codable, Identifiable {

    var name: String?
    var libraryId: UUID?

    /// Workstream C (`NoteBytez20260829v2-Enhancements.md`, Decision 9(a)/11): `nil` for an
    /// ordinary board. Set, this board tracks `boundDocumentId`'s direct-link neighborhood live
    /// (`CanvasDAL.reconcileBoundBoard`) — links → canvas, read-mostly. No `bindingDepth` field:
    /// Decision 10 fixed the neighborhood at 1 hop always.
    var boundDocumentId: UUID?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var canvasBoardId: UUID? = UUID()
    var id: UUID { return self.canvasBoardId! }

    init(name: String, libraryId: UUID) {
        self.name = name
        self.libraryId = libraryId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.canvasBoardId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case name, libraryId, boundDocumentId, createdOn, createdBy, updatedOn, updatedBy, isActive, canvasBoardId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "",
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.boundDocumentId = try container.decodeIfPresent(UUID.self, forKey: .boundDocumentId)
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.canvasBoardId = try container.decodeIfPresent(UUID.self, forKey: .canvasBoardId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.boundDocumentId, forKey: .boundDocumentId)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.canvasBoardId, forKey: .canvasBoardId)
    }

}
