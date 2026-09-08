// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentNotebook.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// Join row for the Document<->Notebook many-to-many relationship. A plain foreign-key model
/// (documentId/notebookId) rather than a SwiftData `@Relationship`, matching Document/Tag's
/// CloudKit-friendly design elsewhere in the app.
@Model
final class DocumentNotebook: Codable, Identifiable {

    var documentId: UUID?
    var notebookId: UUID?
    var libraryId: UUID?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var documentNotebookId: UUID? = UUID()
    var id: UUID { return self.documentNotebookId! }

    init(documentId: UUID, notebookId: UUID, libraryId: UUID) {
        self.documentId = documentId
        self.notebookId = notebookId
        self.libraryId = libraryId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.documentNotebookId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case documentId, notebookId, libraryId, createdOn, createdBy, updatedOn, updatedBy, isActive, documentNotebookId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            documentId: try container.decodeIfPresent(UUID.self, forKey: .documentId) ?? UUID(),
            notebookId: try container.decodeIfPresent(UUID.self, forKey: .notebookId) ?? UUID(),
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.documentNotebookId = try container.decodeIfPresent(UUID.self, forKey: .documentNotebookId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.documentId, forKey: .documentId)
        try container.encode(self.notebookId, forKey: .notebookId)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.documentNotebookId, forKey: .documentNotebookId)
    }

}
