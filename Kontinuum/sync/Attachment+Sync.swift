// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Attachment+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

/// Syncs the `Attachment` metadata row only — `fileName`/`relativePath`/`mimeType`/audit fields.
/// File bytes are never written into a `CKRecord` field; they sync separately via iCloud Drive
/// (the app's ubiquity container, see `AttachmentStorage`), since CloudKit private-database
/// record size limits make inlining infeasible at scale.
extension Attachment: SyncableRecord {

    static var ckRecordType: String { "Attachment" }
    var syncId: UUID? { attachmentId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? {
        guard let documentId else { return nil }
        return Document.fetch(syncId: documentId, in: context)?.libraryId
    }

    func writeFields(to record: CKRecord) {
        record["documentId"] = documentId?.uuidString
        record["fileName"] = fileName
        record["relativePath"] = relativePath
        record["mimeType"] = mimeType
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        documentId = (record["documentId"] as? String).flatMap(UUID.init)
        fileName = record["fileName"] as? String
        relativePath = record["relativePath"] as? String
        mimeType = record["mimeType"] as? String
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> Attachment? {
        let predicate = #Predicate<Attachment> { $0.attachmentId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> Attachment {
        let placeholder = Attachment(documentId: UUID(), fileName: "", relativePath: "", mimeType: "")
        placeholder.attachmentId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
