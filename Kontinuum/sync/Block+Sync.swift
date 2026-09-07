// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Block+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension Block: SyncableRecord {

    static var ckRecordType: String { "Block" }
    var syncId: UUID? { blockId }

    /// The only synced model without its own `libraryId` — resolved via the owning `Document`,
    /// since Phase 12's zone/reference scheme still parents every record straight to its
    /// library's zone (flat, not a Document->Block chain).
    func resolvedLibraryId(in context: ModelContext) -> UUID? {
        guard let documentId else { return nil }
        return Document.fetch(syncId: documentId, in: context)?.libraryId
    }

    func writeFields(to record: CKRecord) {
        record["content"] = content
        record["anchor"] = anchor
        record["headingPath"] = headingPath
        record["sortOrder"] = sortOrder
        record["documentId"] = documentId?.uuidString
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        content = record["content"] as? String
        anchor = record["anchor"] as? String
        headingPath = record["headingPath"] as? String
        sortOrder = record["sortOrder"] as? Int
        documentId = (record["documentId"] as? String).flatMap(UUID.init)
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> Block? {
        let predicate = #Predicate<Block> { $0.blockId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> Block {
        let placeholder = Block(content: "", anchor: "", sortOrder: 0, documentId: UUID())
        placeholder.blockId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
