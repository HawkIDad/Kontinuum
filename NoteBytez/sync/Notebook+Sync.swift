// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Notebook+Sync.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

extension Notebook: SyncableRecord {

    static var ckRecordType: String { "Notebook" }
    var syncId: UUID? { notebookId }

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

    static func fetch(syncId: UUID, in context: ModelContext) -> Notebook? {
        let predicate = #Predicate<Notebook> { $0.notebookId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> Notebook {
        let placeholder = Notebook(name: "", libraryId: UUID())
        placeholder.notebookId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
