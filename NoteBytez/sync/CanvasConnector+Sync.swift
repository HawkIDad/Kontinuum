// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasConnector+Sync.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

extension CanvasConnector: SyncableRecord {

    static var ckRecordType: String { "CanvasConnector" }
    var syncId: UUID? { canvasConnectorId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? {
        guard let canvasBoardId else { return nil }
        return CanvasBoard.fetch(syncId: canvasBoardId, in: context)?.libraryId
    }

    func writeFields(to record: CKRecord) {
        record["canvasBoardId"] = canvasBoardId?.uuidString
        record["fromCardId"] = fromCardId?.uuidString
        record["toCardId"] = toCardId?.uuidString
        record["fromSide"] = fromSide
        record["toSide"] = toSide
        record["color"] = color
        record["label"] = label
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        canvasBoardId = (record["canvasBoardId"] as? String).flatMap(UUID.init)
        fromCardId = (record["fromCardId"] as? String).flatMap(UUID.init)
        toCardId = (record["toCardId"] as? String).flatMap(UUID.init)
        fromSide = record["fromSide"] as? String
        toSide = record["toSide"] as? String
        color = record["color"] as? String
        label = record["label"] as? String
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> CanvasConnector? {
        let predicate = #Predicate<CanvasConnector> { $0.canvasConnectorId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> CanvasConnector {
        let placeholder = CanvasConnector(canvasBoardId: UUID(), fromCardId: UUID(), toCardId: UUID())
        placeholder.canvasConnectorId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
