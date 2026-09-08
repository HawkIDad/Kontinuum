// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentProperty+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension DocumentProperty: SyncableRecord {

    static var ckRecordType: String { "DocumentProperty" }
    var syncId: UUID? { documentPropertyId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["documentId"] = documentId?.uuidString
        record["propertyId"] = propertyId?.uuidString
        record["libraryId"] = libraryId?.uuidString
        record["value"] = value
        record["valueType"] = valueType
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        documentId = (record["documentId"] as? String).flatMap(UUID.init)
        propertyId = (record["propertyId"] as? String).flatMap(UUID.init)
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        value = record["value"] as? String
        valueType = record["valueType"] as? String
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> DocumentProperty? {
        let predicate = #Predicate<DocumentProperty> { $0.documentPropertyId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> DocumentProperty {
        let placeholder = DocumentProperty(documentId: UUID(), propertyId: UUID(), libraryId: UUID(), value: "", valueType: .text)
        placeholder.documentPropertyId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
