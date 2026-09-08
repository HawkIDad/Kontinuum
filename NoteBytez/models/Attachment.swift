// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Attachment.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// A file (image/PDF) attached to a Document. Owned child of `Document`, no `libraryId` of its
/// own — same shape as `Block` (Phase 4's precedent); `AttachmentDAL` joins through
/// `documentId` when a library-wide fetch is needed. File bytes live outside SwiftData/CloudKit
/// in the app's iCloud ubiquity container (see `AttachmentStorage`) — this model is metadata
/// only. `relativePath` is container-root-relative, not an absolute URL, so it stays valid
/// across container-root changes (e.g. a fresh install re-resolving the container).
@Model
final class Attachment: Codable, Identifiable {

    var documentId: UUID?
    var fileName: String?
    var relativePath: String?
    var mimeType: String?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var attachmentId: UUID? = UUID()
    var id: UUID { return self.attachmentId! }

    init(documentId: UUID, fileName: String, relativePath: String, mimeType: String) {
        self.documentId = documentId
        self.fileName = fileName
        self.relativePath = relativePath
        self.mimeType = mimeType
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.attachmentId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case documentId, fileName, relativePath, mimeType, createdOn, createdBy, updatedOn, updatedBy, isActive, attachmentId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            documentId: try container.decodeIfPresent(UUID.self, forKey: .documentId) ?? UUID(),
            fileName: try container.decodeIfPresent(String.self, forKey: .fileName) ?? "",
            relativePath: try container.decodeIfPresent(String.self, forKey: .relativePath) ?? "",
            mimeType: try container.decodeIfPresent(String.self, forKey: .mimeType) ?? ""
        )
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.attachmentId = try container.decodeIfPresent(UUID.self, forKey: .attachmentId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.documentId, forKey: .documentId)
        try container.encode(self.fileName, forKey: .fileName)
        try container.encode(self.relativePath, forKey: .relativePath)
        try container.encode(self.mimeType, forKey: .mimeType)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.attachmentId, forKey: .attachmentId)
    }

}
