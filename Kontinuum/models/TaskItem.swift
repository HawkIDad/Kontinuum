// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskItem.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// A `- [ ]`/`- [x]` checkbox line, indexed for future querying (due-date reminders, priority
/// sort, CloudKit sync per Phase 11's Decisions Log). Named `TaskItem` rather than `Task` to
/// avoid shadowing Swift's own `Task<Success, Failure>` concurrency type, which the sync
/// engine will need throughout the module.
///
/// The Markdown checkbox syntax in the owning `Document`'s content remains the actual source
/// of truth — this row is a reconciled index, re-synced from `Block` content on every save
/// (see `TaskDAL.syncTasks`), not something edited in place.
@Model
final class TaskItem: Codable, Identifiable {

    var content: String?
    var isDone: Bool? = false
    var documentId: UUID?
    var blockId: UUID?
    var libraryId: UUID?

    /// Present in the MVP schema so V1 doesn't need a CloudKit migration to add them, per
    /// Decisions Log — unused by MVP UI.
    var dueDate: Date?
    var priority: Int?

    /// Reserved ahead of Phase 6 (Task Dashboards) of NoteBytez-R1-Implementation.md, same
    /// no-later-migration rationale as `dueDate`/`priority` above. Opaque until Phase 6 decides
    /// its encoding (RFC 5545 RRULE subset vs. a simple enum-encoded string) — unused until then.
    var recurrenceRule: String?

    var createdOn: Date?
    var createdBy: String?
    var updatedOn: Date?
    var updatedBy: String?

    var isActive: Bool? = true

    var taskItemId: UUID? = UUID()
    var id: UUID { return self.taskItemId! }

    init(content: String, isDone: Bool, documentId: UUID, blockId: UUID, libraryId: UUID) {
        self.content = content
        self.isDone = isDone
        self.documentId = documentId
        self.blockId = blockId
        self.libraryId = libraryId
        self.createdOn = Date()
        self.updatedOn = Date()
        self.isActive = true
        self.taskItemId = UUID()
    }

    enum CodingKeys: String, CodingKey {
        case content, isDone, documentId, blockId, libraryId, dueDate, priority, recurrenceRule, createdOn, createdBy, updatedOn, updatedBy, isActive, taskItemId
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            content: try container.decodeIfPresent(String.self, forKey: .content) ?? "",
            isDone: try container.decodeIfPresent(Bool.self, forKey: .isDone) ?? false,
            documentId: try container.decodeIfPresent(UUID.self, forKey: .documentId) ?? UUID(),
            blockId: try container.decodeIfPresent(UUID.self, forKey: .blockId) ?? UUID(),
            libraryId: try container.decodeIfPresent(UUID.self, forKey: .libraryId) ?? UUID()
        )
        self.dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        self.priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        self.recurrenceRule = try container.decodeIfPresent(String.self, forKey: .recurrenceRule)
        self.createdOn = try container.decodeIfPresent(Date.self, forKey: .createdOn)
        self.createdBy = try container.decodeIfPresent(String.self, forKey: .createdBy)
        self.updatedOn = try container.decodeIfPresent(Date.self, forKey: .updatedOn)
        self.updatedBy = try container.decodeIfPresent(String.self, forKey: .updatedBy)
        self.isActive = try container.decodeIfPresent(Bool.self, forKey: .isActive)
        self.taskItemId = try container.decodeIfPresent(UUID.self, forKey: .taskItemId)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.content, forKey: .content)
        try container.encode(self.isDone, forKey: .isDone)
        try container.encode(self.documentId, forKey: .documentId)
        try container.encode(self.blockId, forKey: .blockId)
        try container.encode(self.libraryId, forKey: .libraryId)
        try container.encode(self.dueDate, forKey: .dueDate)
        try container.encode(self.priority, forKey: .priority)
        try container.encode(self.recurrenceRule, forKey: .recurrenceRule)
        try container.encode(self.createdOn, forKey: .createdOn)
        try container.encode(self.createdBy, forKey: .createdBy)
        try container.encode(self.updatedOn, forKey: .updatedOn)
        try container.encode(self.updatedBy, forKey: .updatedBy)
        try container.encode(self.isActive, forKey: .isActive)
        try container.encode(self.taskItemId, forKey: .taskItemId)
    }

}
