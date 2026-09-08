// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Notebook.swift
//  NoteBytez
//

import Foundation
import SwiftData

@Model
final class Notebook: Codable, Identifiable {

    var name: String?
    var libraryId: UUID?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var notebookId: UUID? = UUID()
    var id: UUID { return self.notebookId! }

    init(name: String, libraryId: UUID) {
        self.name = name
        self.libraryId = libraryId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.notebookId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case name, libraryId, createdOn, createdBy, updatedOn, updatedBy, isActive, notebookId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            name: try container.decodeIfPresent(String.self, forKey: .name) ?? "",
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.notebookId = try container.decodeIfPresent(UUID.self, forKey: .notebookId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.notebookId, forKey: .notebookId)
    }

}
