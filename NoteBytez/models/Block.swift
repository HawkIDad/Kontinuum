// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Block.swift
//  NoteBytez
//

import Foundation
import SwiftData

@Model
final class Block: Codable, Identifiable {

    var content: String?
    var anchor: String?
    var headingPath: String?
    var sortOrder: Int?
    var documentId: UUID?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var blockId: UUID? = UUID()
    var id: UUID { return self.blockId! }

    init(content: String, anchor: String, sortOrder: Int, documentId: UUID) {
        self.content = content
        self.anchor = anchor
        self.sortOrder = sortOrder
        self.documentId = documentId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.blockId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case content, anchor, headingPath, sortOrder, documentId, createdOn, createdBy, updatedOn, updatedBy, isActive, blockId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            content: try container.decodeIfPresent(String.self, forKey: .content) ?? "",
            anchor: try container.decodeIfPresent(String.self, forKey: .anchor) ?? "",
            sortOrder: try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0,
            documentId: try container.decodeIfPresent(UUID.self, forKey: .documentId) ?? UUID()
        )
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.blockId = try container.decodeIfPresent(UUID.self, forKey: .blockId)
        self.headingPath = try container.decodeIfPresent(String.self, forKey: .headingPath)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.content, forKey: .content)
        try container.encode(self.anchor, forKey: .anchor)
        try container.encode(self.headingPath, forKey: .headingPath)
        try container.encode(self.sortOrder, forKey: .sortOrder)
        try container.encode(self.documentId, forKey: .documentId)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.blockId, forKey: .blockId)
    }

}
