// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Property.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// Typed field a library's Properties can hold. Stored as a plain `String` for CloudKit
/// safety (no enum-typed `@Model` fields); `PropertyDAL`/`PropertyParser` are the only code
/// that should construct one from a raw value.
enum PropertyValueType: String, Codable, CaseIterable {
    case text
    case number
    case date
    case checkbox
    case list
}

/// Library-scoped catalog of property names in use — analogous to `Tag`, but for typed
/// metadata rather than free labels. A document's actual values live in `DocumentProperty`,
/// the join model, matching the `Tag`/`DocumentTag` split.
@Model
final class Property: Codable, Identifiable {

    /// Exact, as-authored name (unlike `Tag.name`, not case-folded — a Property is a typed
    /// field a user names once via a Note Template or the Properties editor, not a
    /// freely-retyped inline token, so there's no duplicate-spelling risk to canonicalize away).
    var name: String?
    var valueType: String?
    var libraryId: UUID?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var propertyId: UUID? = UUID()
    var id: UUID { return self.propertyId! }

    init(name: String, valueType: PropertyValueType, libraryId: UUID) {
        self.name = name
        self.valueType = valueType.rawValue
        self.libraryId = libraryId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.propertyId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case name, valueType, libraryId, createdOn, createdBy, updatedOn, updatedBy, isActive, propertyId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "",
            valueType: (try container.decodeIfPresent(String.self, forKey: .valueType)).flatMap(PropertyValueType.init) ?? .text,
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.propertyId = try container.decodeIfPresent(UUID.self, forKey: .propertyId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.valueType, forKey: .valueType)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.propertyId, forKey: .propertyId)
    }

}
