// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentNotebook+Sync.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

extension DocumentNotebook: SyncableRecord {

    static var ckRecordType: String { "DocumentNotebook" }
    var syncId: UUID? { documentNotebookId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["documentId"] = documentId?.uuidString
        record["notebookId"] = notebookId?.uuidString
        record["libraryId"] = libraryId?.uuidString
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        documentId = (record["documentId"] as? String).flatMap(UUID.init)
        notebookId = (record["notebookId"] as? String).flatMap(UUID.init)
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> DocumentNotebook? {
        let predicate = #Predicate<DocumentNotebook> { $0.documentNotebookId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> DocumentNotebook {
        let placeholder = DocumentNotebook(documentId: UUID(), notebookId: UUID(), libraryId: UUID())
        placeholder.documentNotebookId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
