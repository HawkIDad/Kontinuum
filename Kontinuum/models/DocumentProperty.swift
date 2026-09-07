// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentProperty.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// Join row for the Document<->Property many-to-many relationship, carrying that document's
/// value for the property. A plain foreign-key model (documentId/propertyId), matching
/// `DocumentTag`/`DocumentNotebook`'s CloudKit-friendly design elsewhere in the app.
///
/// `value` is always the canonical string form of the typed value — a `list` value joins its
/// items with "; ", a `checkbox` value is "true"/"false", a `date` value is `yyyy-MM-dd` — see
/// `PropertyParser`. `valueType` mirrors `Property.valueType` here too, so a value can be
/// interpreted (e.g. for search/filter, Phase 6's Task Dashboard-style queries) without a
/// second fetch back to the `Property` definition.
@Model
final class DocumentProperty: Codable, Identifiable {

    var documentId: UUID?
    var propertyId: UUID?
    var libraryId: UUID?
    var value: String?
    var valueType: String?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var documentPropertyId: UUID? = UUID()
    var id: UUID { return self.documentPropertyId! }

    init(documentId: UUID, propertyId: UUID, libraryId: UUID, value: String, valueType: PropertyValueType) {
        self.documentId = documentId
        self.propertyId = propertyId
        self.libraryId = libraryId
        self.value = value
        self.valueType = valueType.rawValue
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.documentPropertyId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case documentId, propertyId, libraryId, value, valueType, createdOn, createdBy, updatedOn, updatedBy, isActive, documentPropertyId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            documentId: try container.decodeIfPresent(UUID.self, forKey: .documentId) ?? UUID(),
            propertyId: try container.decodeIfPresent(UUID.self, forKey: .propertyId) ?? UUID(),
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID(),
            value: try container.decodeIfPresent(String.self, forKey: .value) ?? "",
            valueType: (try container.decodeIfPresent(String.self, forKey: .valueType)).flatMap(PropertyValueType.init) ?? .text
        )
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.documentPropertyId = try container.decodeIfPresent(UUID.self, forKey: .documentPropertyId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.documentId, forKey: .documentId)
        try container.encode(self.propertyId, forKey: .propertyId)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.value, forKey: .value)
        try container.encode(self.valueType, forKey: .valueType)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.documentPropertyId, forKey: .documentPropertyId)
    }

}
