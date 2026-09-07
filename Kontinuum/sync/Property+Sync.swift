// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Property+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension Property: SyncableRecord {

    static var ckRecordType: String { "Property" }
    var syncId: UUID? { propertyId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["name"] = name
        record["valueType"] = valueType
        record["libraryId"] = libraryId?.uuidString
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        name = record["name"] as? String
        valueType = record["valueType"] as? String
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> Property? {
        let predicate = #Predicate<Property> { $0.propertyId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> Property {
        let placeholder = Property(name: "", valueType: .text, libraryId: UUID())
        placeholder.propertyId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
