// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Document.swift
//  NoteBytez
//

import Foundation
import SwiftData

@Model
final class Document: Codable, Identifiable {

    var title: String?
    var content: String?
    var libraryId: UUID?

    /// Set only for the auto-created "today" journal page (S3) — `journalDate` is that page's
    /// day, normalized to midnight, and is how `JournalDAL` looks a day's entry back up
    /// idempotently. Ordinary notes leave both nil.
    var isJournalEntry: Bool? = false
    var journalDate: Date?

    /// Set only on a document created via `NotebookDAL.promote` — the stable `Block.blockId`
    /// (and its owning document) this note was promoted from. Independent of the `[[wikilink]]`
    /// back-reference in `content`, which is text and survives rename but not retitle-driven
    /// ambiguity; this is the addressable, block-aware provenance link.
    var promotedFromDocumentId: UUID?
    var promotedFromBlockId: UUID?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var documentId: UUID? = UUID()
    var id: UUID { return self.documentId! }

    init(title: String, content: String, libraryId: UUID) {
        self.title = title
        self.content = content
        self.libraryId = libraryId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.documentId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case title, content, libraryId, isJournalEntry, journalDate, promotedFromDocumentId, promotedFromBlockId, createdOn, createdBy, updatedOn, updatedBy, isActive, documentId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            title: try container.decodeIfPresent(String.self, forKey: .title) ?? "",
            content: try container.decodeIfPresent(String.self, forKey: .content) ?? "",
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.isJournalEntry = try container.decodeIfPresent(Bool.self, forKey: .isJournalEntry)
        self.journalDate = try container.decodeIfPresent(Date.self, forKey: .journalDate)
        self.promotedFromDocumentId = try container.decodeIfPresent(UUID.self, forKey: .promotedFromDocumentId)
        self.promotedFromBlockId = try container.decodeIfPresent(UUID.self, forKey: .promotedFromBlockId)
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.documentId = try container.decodeIfPresent(UUID.self, forKey: .documentId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.title, forKey: .title)
        try container.encode(self.content, forKey: .content)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.isJournalEntry, forKey: .isJournalEntry)
        try container.encode(self.journalDate, forKey: .journalDate)
        try container.encode(self.promotedFromDocumentId, forKey: .promotedFromDocumentId)
        try container.encode(self.promotedFromBlockId, forKey: .promotedFromBlockId)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.documentId, forKey: .documentId)
    }

}
