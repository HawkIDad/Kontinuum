// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NoteTemplate+Sync.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData

extension NoteTemplate: SyncableRecord {

    static var ckRecordType: String { "NoteTemplate" }
    var syncId: UUID? { noteTemplateId }

    func resolvedLibraryId(in context: ModelContext) -> UUID? { libraryId }

    func writeFields(to record: CKRecord) {
        record["name"] = name
        record["templateGroupId"] = templateGroupId?.uuidString
        record["libraryId"] = libraryId?.uuidString
        record["fieldsJSON"] = fieldsJSON
        record["bodyTemplate"] = bodyTemplate
        record["createdOn"] = createdOn
        record["createdBy"] = createdBy
        record["updatedOn"] = updatedOn
        record["updatedBy"] = updatedBy
        record["isActive"] = isActive
    }

    func readFields(from record: CKRecord) {
        name = record["name"] as? String
        templateGroupId = (record["templateGroupId"] as? String).flatMap(UUID.init)
        libraryId = (record["libraryId"] as? String).flatMap(UUID.init)
        fieldsJSON = record["fieldsJSON"] as? String
        bodyTemplate = record["bodyTemplate"] as? String
        createdOn = record["createdOn"] as? Date
        createdBy = record["createdBy"] as? String
        updatedOn = record["updatedOn"] as? Date
        updatedBy = record["updatedBy"] as? String
        isActive = record["isActive"] as? Bool
    }

    static func fetch(syncId: UUID, in context: ModelContext) -> NoteTemplate? {
        let predicate = #Predicate<NoteTemplate> { $0.noteTemplateId == syncId }
        return try? context.fetch(FetchDescriptor(predicate: predicate)).first
    }

    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> NoteTemplate {
        let placeholder = NoteTemplate(name: "", templateGroupId: UUID(), libraryId: UUID())
        placeholder.noteTemplateId = syncId
        context.insert(placeholder)
        return placeholder
    }

}
