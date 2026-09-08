// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  JournalTemplateGroup.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// Join row attaching a `TemplateGroup` directly to a library's Journal — library-scoped
/// rather than a `documentId`/notebook FK, since Journal has no container model of its own
/// (per MVP's Decisions Log: "Journal has no container model... a single ongoing per-library
/// stream"). Many-to-many with `TemplateGroup` in the same sense `NotebookTemplateGroup` is:
/// a library can attach more than one journal-facing group.
@Model
final class JournalTemplateGroup: Codable, Identifiable {

    var libraryId: UUID?
    var templateGroupId: UUID?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var journalTemplateGroupId: UUID? = UUID()
    var id: UUID { return self.journalTemplateGroupId! }

    init(libraryId: UUID, templateGroupId: UUID) {
        self.libraryId = libraryId
        self.templateGroupId = templateGroupId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.journalTemplateGroupId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case libraryId, templateGroupId, createdOn, createdBy, updatedOn, updatedBy, isActive, journalTemplateGroupId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID(),
            templateGroupId: try container.decodeIfPresent(UUID.self, forKey: .templateGroupId) ?? UUID()
        )
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.journalTemplateGroupId = try container.decodeIfPresent(UUID.self, forKey: .journalTemplateGroupId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.templateGroupId, forKey: .templateGroupId)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.journalTemplateGroupId, forKey: .journalTemplateGroupId)
    }

}
