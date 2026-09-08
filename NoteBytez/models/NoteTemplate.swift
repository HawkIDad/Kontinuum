// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NoteTemplate.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// One field a `NoteTemplate` pre-fills — a `Property` name/type pair plus the default value
/// to seed it with. Not a `@Model`/CloudKit table of its own: a template's field list is
/// small, always read/written as a whole unit, and never queried across templates, so it's
/// stored as a single JSON-encoded `String` on `NoteTemplate` (`fieldsJSON`) rather than a new
/// synced join model — the same "flat scalar field over another relationship table" preference
/// this app already applies elsewhere (e.g. `DocumentProperty.value`'s canonical-string form).
/// `nonisolated`: plain serializable data with no UI/shared-state ties, opted out of this
/// target's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — otherwise its `Codable`/`Equatable`
/// conformances are themselves MainActor-isolated, which `JSONDecoder`/`JSONEncoder`'s nonisolated
/// stdlib entry points and test assertions (`#expect(a == b)`) can't call into (a warning today,
/// a Swift 6 language-mode error).
nonisolated struct NoteTemplateField: Codable, Identifiable, Equatable {
    var name: String
    var valueType: PropertyValueType
    var defaultValue: String
    var id: String { name }
}

/// Named preset that pre-fills a Document's Properties for a given entity type (e.g.
/// Character, Location, Vendor), per NoteBytez-ReleaseFeatures.md's Version 1 section. Belongs
/// to exactly one `TemplateGroup` (simple FK, not many-to-many) — a template is authored for
/// one domain; a shared field set becomes its own template rather than joining multiple groups.
@Model
final class NoteTemplate: Codable, Identifiable {

    var name: String?
    var templateGroupId: UUID?
    var libraryId: UUID?
    var fieldsJSON: String?

    /// Optional Markdown scaffold woven into a new Document's body when the template is applied
    /// at creation (headings, section prompts, `- [ ]` checklist lines). `nil`/empty = a
    /// fields-only template, unchanged from the Version 1 behavior. Never injected by
    /// `TemplateDAL.applyRetroactively` — see that method.
    var bodyTemplate: String?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var noteTemplateId: UUID? = UUID()
    var id: UUID { return self.noteTemplateId! }

    init(name: String, templateGroupId: UUID, libraryId: UUID, fields: [NoteTemplateField] = [], bodyTemplate: String? = nil) {
        self.name = name
        self.templateGroupId = templateGroupId
        self.libraryId = libraryId
        self.fieldsJSON = Self.encode(fields)
        self.bodyTemplate = bodyTemplate
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.noteTemplateId = UUID()
    }

    var fields: [NoteTemplateField] {
        get { Self.decode(fieldsJSON) }
        set { fieldsJSON = Self.encode(newValue) }
    }

    private static func encode(_ fields: [NoteTemplateField]) -> String {
        (try? String(data: JSONEncoder().encode(fields), encoding: .utf8)) ?? "[]"
    }

    private static func decode(_ json: String?) -> [NoteTemplateField] {
        guard let json, let data = json.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode([NoteTemplateField].self, from: data)) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case name, templateGroupId, libraryId, fieldsJSON, bodyTemplate, createdOn, createdBy, updatedOn, updatedBy, isActive, noteTemplateId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "",
            templateGroupId: try container.decodeIfPresent(UUID.self, forKey: .templateGroupId) ?? UUID(),
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.fieldsJSON = try container.decodeIfPresent(String.self, forKey: .fieldsJSON)
        self.bodyTemplate = try container.decodeIfPresent(String.self, forKey: .bodyTemplate)
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.noteTemplateId = try container.decodeIfPresent(UUID.self, forKey: .noteTemplateId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.templateGroupId, forKey: .templateGroupId)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.fieldsJSON, forKey: .fieldsJSON)
        try container.encode(self.bodyTemplate, forKey: .bodyTemplate)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.noteTemplateId, forKey: .noteTemplateId)
    }

}
