// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasCard+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension CanvasCard: SyncableRecord {

    static var ckRecordType: String { "CanvasCard" }
    var syncId: UUID? { canvasCardId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? {
        guard let canvasBoardId else { return nil }
        return CanvasBoard.fetch(syncId: canvasBoardId, in: context)?.libraryId
    }

    func writeFields(to record: CKRecord) {
        record["canvasBoardId"] = canvasBoardId?.uuidString
        record["cardType"] = cardType
        record["documentId"] = documentId?.uuidString
        record["attachmentId"] = attachmentId?.uuidString
        record["url"] = url
        record["label"] = label
        record["positionX"] = positionX
        record["positionY"] = positionY
        record["width"] = width
        record["height"] = height
        record["color"] = color
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        canvasBoardId = (record["canvasBoardId"] as? String).flatMap(UUID.init)
        cardType = record["cardType"] as? String
        documentId = (record["documentId"] as? String).flatMap(UUID.init)
        attachmentId = (record["attachmentId"] as? String).flatMap(UUID.init)
        url = record["url"] as? String
        label = record["label"] as? String
        positionX = record["positionX"] as? Double
        positionY = record["positionY"] as? Double
        width = record["width"] as? Double
        height = record["height"] as? Double
        color = record["color"] as? String
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> CanvasCard? {
        let predicate = #Predicate<CanvasCard> { $0.canvasCardId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> CanvasCard {
        let placeholder = CanvasCard(canvasBoardId: UUID(), cardType: .note, positionX: 0, positionY: 0, width: 0, height: 0)
        placeholder.canvasCardId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
