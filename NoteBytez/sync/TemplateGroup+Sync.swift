// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateGroup+Sync.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

extension TemplateGroup: SyncableRecord {

    static var ckRecordType: String { "TemplateGroup" }
    var syncId: UUID? { templateGroupId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["name"] = name
        record["libraryId"] = libraryId?.uuidString
        record["sourcePackId"] = sourcePackId
        record["sourcePackVersion"] = sourcePackVersion
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        name = record["name"] as? String
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        sourcePackId = record["sourcePackId"] as? String
        sourcePackVersion = record["sourcePackVersion"] as? Int
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> TemplateGroup? {
        let predicate = #Predicate<TemplateGroup> { $0.templateGroupId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> TemplateGroup {
        let placeholder = TemplateGroup(name: "", libraryId: UUID())
        placeholder.templateGroupId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
