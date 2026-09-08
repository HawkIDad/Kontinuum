// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Plugin+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension Plugin: SyncableRecord {

    static var ckRecordType: String { "Plugin" }
    var syncId: UUID? { pluginId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["name"] = name
        record["libraryId"] = libraryId?.uuidString
        record["entryScript"] = entryScript
        record["permissionsJSON"] = permissionsJSON
        record["isEnabled"] = isEnabled
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        name = record["name"] as? String
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        entryScript = record["entryScript"] as? String
        permissionsJSON = record["permissionsJSON"] as? String
        isEnabled = record["isEnabled"] as? Bool
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> Plugin? {
        let predicate = #Predicate<Plugin> { $0.pluginId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> Plugin {
        let placeholder = Plugin(name: "", libraryId: UUID(), entryScript: "", permissions: [])
        placeholder.pluginId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
