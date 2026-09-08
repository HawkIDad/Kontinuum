// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateGroup.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// Named, user-owned bundle of `NoteTemplate`s for a domain of work (e.g. "Fiction Writing",
/// "Wedding Planning"), per NoteBytez-ReleaseFeatures.md's Version 1 section. Attaches to
/// Notebooks (`NotebookTemplateGroup`) and/or a library's Journal (`JournalTemplateGroup`) via
/// separate many-to-many joins, so one group built once can back several Notebooks at once —
/// same shape as `Notebook` itself.
@Model
final class TemplateGroup: Codable, Identifiable {

    var name: String?
    var libraryId: UUID?

    /// Set when this group was materialized from a bundled Template Pack (`TemplatePackDAL`).
    /// `nil` for a hand-created group. `sourcePackVersion` records which bundled version was
    /// applied, so the gallery can offer a non-destructive "Update available".
    var sourcePackId: String?
    var sourcePackVersion: Int?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var templateGroupId: UUID? = UUID()
    var id: UUID { return self.templateGroupId! }

    init(name: String, libraryId: UUID, sourcePackId: String? = nil, sourcePackVersion: Int? = nil) {
        self.name = name
        self.libraryId = libraryId
        self.sourcePackId = sourcePackId
        self.sourcePackVersion = sourcePackVersion
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.templateGroupId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case name, libraryId, sourcePackId, sourcePackVersion, createdOn, createdBy, updatedOn, updatedBy, isActive, templateGroupId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "",
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.sourcePackId = try container.decodeIfPresent(String.self, forKey: .sourcePackId)
        self.sourcePackVersion = try container.decodeIfPresent(Int.self, forKey: .sourcePackVersion)
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.templateGroupId = try container.decodeIfPresent(UUID.self, forKey: .templateGroupId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.sourcePackId, forKey: .sourcePackId)
        try container.encode(self.sourcePackVersion, forKey: .sourcePackVersion)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.templateGroupId, forKey: .templateGroupId)
    }

}
