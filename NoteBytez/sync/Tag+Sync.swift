// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Tag+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension Tag: SyncableRecord {

    static var ckRecordType: String { "Tag" }
    var syncId: UUID? { tagId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["name"] = name
        record["libraryId"] = libraryId?.uuidString
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        name = record["name"] as? String
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> Tag? {
        let predicate = #Predicate<Tag> { $0.tagId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> Tag {
        let placeholder = Tag(name: "", libraryId: UUID())
        placeholder.tagId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
