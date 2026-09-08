// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookTemplateGroup.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// Join row for the Notebook<->TemplateGroup many-to-many relationship — a group built once
/// (e.g. "Fiction Writing") can back several book-series Notebooks at once, and a Notebook can
/// draw on more than one group. A plain foreign-key model, mirroring `DocumentNotebook`.
@Model
final class NotebookTemplateGroup: Codable, Identifiable {

    var notebookId: UUID?
    var templateGroupId: UUID?
    var libraryId: UUID?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var notebookTemplateGroupId: UUID? = UUID()
    var id: UUID { return self.notebookTemplateGroupId! }

    init(notebookId: UUID, templateGroupId: UUID, libraryId: UUID) {
        self.notebookId = notebookId
        self.templateGroupId = templateGroupId
        self.libraryId = libraryId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.notebookTemplateGroupId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case notebookId, templateGroupId, libraryId, createdOn, createdBy, updatedOn, updatedBy, isActive, notebookTemplateGroupId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            notebookId: try container.decodeIfPresent(UUID.self, forKey: .notebookId) ?? UUID(),
            templateGroupId: try container.decodeIfPresent(UUID.self, forKey: .templateGroupId) ?? UUID(),
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.notebookTemplateGroupId = try container.decodeIfPresent(UUID.self, forKey: .notebookTemplateGroupId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.notebookId, forKey: .notebookId)
        try container.encode(self.templateGroupId, forKey: .templateGroupId)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.notebookTemplateGroupId, forKey: .notebookTemplateGroupId)
    }

}
