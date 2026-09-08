// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedView.swift
//  Kontinuum
//

import Foundation
import SwiftData

enum SavedViewQueryType: String, Codable, CaseIterable {
    case search
    case task
    case graph
}

/// Everything needed to re-run a saved Advanced Search (Phase 5) query — mirrors
/// `SearchViewModel`'s own state exactly, so a saved view resumes precisely how it was left.
/// `nonisolated`: plain serializable data with no UI/shared-state ties, opted out of this
/// target's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — otherwise its `Codable` conformance
/// is itself MainActor-isolated, which `JSONDecoder`/`JSONEncoder`'s own nonisolated stdlib
/// `decode`/`encode` entry points (called from `SavedView.decode`/`encode` below) can't invoke
/// (a warning today, a Swift 6 language-mode error).
nonisolated struct SavedSearchDefinition: Codable, Equatable {
    var query: String
    var scope: String
    var isAdvancedMode: Bool
}

/// Everything needed to re-run a saved Task Dashboard (Phase 6) filter combination — mirrors
/// `TaskDashboardViewModel`'s own filter state. `nonisolated` for the same reason as
/// `SavedSearchDefinition` above.
nonisolated struct SavedTaskDefinition: Codable, Equatable {
    var statusFilter: String
    var dateFilter: String
    var tagFilter: String
}

/// A saved S8 force-graph filter preset — the filter itself (`GraphFilter`) plus the focus note
/// it was saved from, since a graph has no meaning without a center. `nonisolated` for the same
/// reason as the two definitions above.
nonisolated struct SavedGraphDefinition: Codable, Equatable {
    var focusDocumentId: UUID
    var filter: GraphFilter
}

/// A named, pinned search or task query, per NoteBytez-ReleaseFeatures.md's Version 1 "Saved
/// views" — "save a filtered search or task query as a named, pinned view." Re-evaluates live
/// on open (`SavedViewViewModel`), never a frozen result snapshot from save time.
///
/// `queryType` + `definitionJSON` store whichever of `SavedSearchDefinition`/
/// `SavedTaskDefinition` applies, as a single JSON-encoded `String` — the same "flat scalar
/// field over a second table" choice `NoteTemplate.fieldsJSON` already made for a small
/// always-together structure that's never queried piecemeal across rows.
@Model
final class SavedView: Codable, Identifiable {

    var name: String?
    var libraryId: UUID?
    var queryType: String?
    var definitionJSON: String?
    var sortOrder: Int?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var savedViewId: UUID? = UUID()
    var id: UUID { return self.savedViewId! }

    init(name: String, libraryId: UUID, queryType: SavedViewQueryType, sortOrder: Int) {
        self.name = name
        self.libraryId = libraryId
        self.queryType = queryType.rawValue
        self.sortOrder = sortOrder
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.savedViewId = UUID()
    }

    var savedQueryType: SavedViewQueryType? {
        queryType.flatMap(SavedViewQueryType.init)
    }

    var searchDefinition: SavedSearchDefinition? {
        get { Self.decode(definitionJSON) }
        set { definitionJSON = Self.encode(newValue) }
    }

    var taskDefinition: SavedTaskDefinition? {
        get { Self.decode(definitionJSON) }
        set { definitionJSON = Self.encode(newValue) }
    }

    /// A saved S8 force-graph filter preset (Decision 5, `20260829v2-Enhancements.md`
    /// Workstream A) — same "reuse `definitionJSON`, no new store" shape as the two above.
    /// `focusDocumentId` (the note the filter was saved from) travels alongside the filter
    /// itself since a graph view has no meaning without a focus note to center on.
    var graphDefinition: SavedGraphDefinition? {
        get { Self.decode(definitionJSON) }
        set { definitionJSON = Self.encode(newValue) }
    }

    private static func encode<T: Encodable>(_ value: T?) -> String? {
        guard let value else { return nil }
        return try? String(data: JSONEncoder().encode(value), encoding: .utf8)
    }

    private static func decode<T: Decodable>(_ json: String?) -> T? {
        guard let json, let data = json.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    enum CodingKeys: String, CodingKey {
        case name, libraryId, queryType, definitionJSON, sortOrder, createdOn, createdBy, updatedOn, updatedBy, isActive, savedViewId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "",
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID(),
            queryType: (try container.decodeIfPresent(String.self, forKey: .queryType)).flatMap(SavedViewQueryType.init) ?? .search,
            sortOrder: try container.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        )
        self.definitionJSON = try container.decodeIfPresent(String.self, forKey: .definitionJSON)
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.savedViewId = try container.decodeIfPresent(UUID.self, forKey: .savedViewId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.queryType, forKey: .queryType)
        try container.encode(self.definitionJSON, forKey: .definitionJSON)
        try container.encode(self.sortOrder, forKey: .sortOrder)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.savedViewId, forKey: .savedViewId)
    }

}
