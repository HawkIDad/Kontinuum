// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedView+Sync.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

extension SavedView: SyncableRecord {

    static var ckRecordType: String { "SavedView" }
    var syncId: UUID? { savedViewId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["name"] = name
        record["libraryId"] = libraryId?.uuidString
        record["queryType"] = queryType
        record["definitionJSON"] = definitionJSON
        record["sortOrder"] = sortOrder
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        name = record["name"] as? String
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        queryType = record["queryType"] as? String
        definitionJSON = record["definitionJSON"] as? String
        sortOrder = record["sortOrder"] as? Int
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> SavedView? {
        let predicate = #Predicate<SavedView> { $0.savedViewId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> SavedView {
        let placeholder = SavedView(name: "", libraryId: UUID(), queryType: .search, sortOrder: 0)
        placeholder.savedViewId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
