// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Document+Sync.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

extension Document: SyncableRecord {

    static var ckRecordType: String { "Document" }
    var syncId: UUID? { documentId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["title"] = title
        record["content"] = content
        record["libraryId"] = libraryId?.uuidString
        record["isJournalEntry"] = isJournalEntry
        record["journalDate"] = journalDate
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        title = record["title"] as? String
        content = record["content"] as? String
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        isJournalEntry = record["isJournalEntry"] as? Bool
        journalDate = record["journalDate"] as? Date
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> Document? {
        let predicate = #Predicate<Document> { $0.documentId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> Document {
        let placeholder = Document(title: "", content: "", libraryId: UUID())
        placeholder.documentId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
