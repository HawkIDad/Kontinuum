// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Library+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension Library: SyncableRecord {

    static var ckRecordType: String { "Library" }
    var syncId: UUID? { libraryId }

    /// A Library is its own zone's root record — no separate lookup needed.
    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["name"] = name
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        name = record["name"] as? String
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> Library? {
        let predicate = #Predicate<Library> { $0.libraryId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> Library {
        let placeholder = Library(name: "")
        placeholder.libraryId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
