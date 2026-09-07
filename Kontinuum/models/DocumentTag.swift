// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentTag.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// Join row for the Document<->Tag many-to-many relationship. A plain foreign-key model
/// (documentId/tagId) rather than a SwiftData `@Relationship`, matching Document/Block's
/// CloudKit-friendly design elsewhere in the app.
@Model
final class DocumentTag: Codable, Identifiable {

    var documentId: UUID?
    var tagId: UUID?
    var libraryId: UUID?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var documentTagId: UUID? = UUID()
    var id: UUID { return self.documentTagId! }

    init(documentId: UUID, tagId: UUID, libraryId: UUID) {
        self.documentId = documentId
        self.tagId = tagId
        self.libraryId = libraryId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.documentTagId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case documentId, tagId, libraryId, createdOn, createdBy, updatedOn, updatedBy, isActive, documentTagId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            documentId: try container.decodeIfPresent(UUID.self, forKey: .documentId) ?? UUID(),
            tagId: try container.decodeIfPresent(UUID.self, forKey: .tagId) ?? UUID(),
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.documentTagId = try container.decodeIfPresent(UUID.self, forKey: .documentTagId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.documentId, forKey: .documentId)
        try container.encode(self.tagId, forKey: .tagId)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.documentTagId, forKey: .documentTagId)
    }

}
