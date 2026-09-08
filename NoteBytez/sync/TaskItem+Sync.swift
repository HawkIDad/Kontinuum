// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskItem+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension TaskItem: SyncableRecord {

    static var ckRecordType: String { "TaskItem" }
    var syncId: UUID? { taskItemId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["content"] = content
        record["isDone"] = isDone
        record["documentId"] = documentId?.uuidString
        record["blockId"] = blockId?.uuidString
        record["libraryId"] = libraryId?.uuidString
        record["dueDate"] = dueDate
        record["priority"] = priority
        record["recurrenceRule"] = recurrenceRule
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        content = record["content"] as? String
        isDone = record["isDone"] as? Bool
        documentId = (record["documentId"] as? String).flatMap(UUID.init)
        blockId = (record["blockId"] as? String).flatMap(UUID.init)
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        dueDate = record["dueDate"] as? Date
        priority = record["priority"] as? Int
        recurrenceRule = record["recurrenceRule"] as? String
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> TaskItem? {
        let predicate = #Predicate<TaskItem> { $0.taskItemId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> TaskItem {
        let placeholder = TaskItem(content: "", isDone: false, documentId: UUID(), blockId: UUID(), libraryId: UUID())
        placeholder.taskItemId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
