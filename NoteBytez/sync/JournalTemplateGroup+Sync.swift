// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  JournalTemplateGroup+Sync.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

extension JournalTemplateGroup: SyncableRecord {

    static var ckRecordType: String { "JournalTemplateGroup" }
    var syncId: UUID? { journalTemplateGroupId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["libraryId"] = libraryId?.uuidString
        record["templateGroupId"] = templateGroupId?.uuidString
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        templateGroupId = (record["templateGroupId"] as? String).flatMap(UUID.init)
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> JournalTemplateGroup? {
        let predicate = #Predicate<JournalTemplateGroup> { $0.journalTemplateGroupId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> JournalTemplateGroup {
        let placeholder = JournalTemplateGroup(libraryId: UUID(), templateGroupId: UUID())
        placeholder.journalTemplateGroupId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
