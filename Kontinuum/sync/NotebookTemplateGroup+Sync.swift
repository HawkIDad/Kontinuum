// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookTemplateGroup+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension NotebookTemplateGroup: SyncableRecord {

    static var ckRecordType: String { "NotebookTemplateGroup" }
    var syncId: UUID? { notebookTemplateGroupId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["notebookId"] = notebookId?.uuidString
        record["templateGroupId"] = templateGroupId?.uuidString
        record["libraryId"] = libraryId?.uuidString
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        notebookId = (record["notebookId"] as? String).flatMap(UUID.init)
        templateGroupId = (record["templateGroupId"] as? String).flatMap(UUID.init)
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> NotebookTemplateGroup? {
        let predicate = #Predicate<NotebookTemplateGroup> { $0.notebookTemplateGroupId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> NotebookTemplateGroup {
        let placeholder = NotebookTemplateGroup(notebookId: UUID(), templateGroupId: UUID(), libraryId: UUID())
        placeholder.notebookTemplateGroupId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
