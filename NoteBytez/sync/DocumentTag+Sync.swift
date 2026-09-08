// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentTag+Sync.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

extension DocumentTag: SyncableRecord {

    static var ckRecordType: String { "DocumentTag" }
    var syncId: UUID? { documentTagId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["documentId"] = documentId?.uuidString
        record["tagId"] = tagId?.uuidString
        record["libraryId"] = libraryId?.uuidString
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        documentId = (record["documentId"] as? String).flatMap(UUID.init)
        tagId = (record["tagId"] as? String).flatMap(UUID.init)
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> DocumentTag? {
        let predicate = #Predicate<DocumentTag> { $0.documentTagId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> DocumentTag {
        let placeholder = DocumentTag(documentId: UUID(), tagId: UUID(), libraryId: UUID())
        placeholder.documentTagId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
