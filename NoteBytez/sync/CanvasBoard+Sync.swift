// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasBoard+Sync.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

extension CanvasBoard: SyncableRecord {

    static var ckRecordType: String { "CanvasBoard" }
    var syncId: UUID? { canvasBoardId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["name"] = name
        record["libraryId"] = libraryId?.uuidString
        record["boundDocumentId"] = boundDocumentId?.uuidString
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        name = record["name"] as? String
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        boundDocumentId = (record["boundDocumentId"] as? String).flatMap(UUID.init)
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> CanvasBoard? {
        let predicate = #Predicate<CanvasBoard> { $0.canvasBoardId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> CanvasBoard {
        let placeholder = CanvasBoard(name: "", libraryId: UUID())
        placeholder.canvasBoardId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
