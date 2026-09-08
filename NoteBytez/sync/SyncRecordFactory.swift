// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncRecordFactory.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

/// The only place that knows about all 20 synced model types — everything else in `sync/`
/// works through the generic `SyncableRecord` protocol.
enum SyncRecordFactory {

    /// Builds the outgoing `CKRecord` for a pending `.saveRecord` change. `CKRecord.ID` alone
    /// doesn't carry a record type, so this tries each model's table in turn by `syncId` —
    /// safe because every model's ID is an independently-generated UUID, effectively never
    /// colliding across tables.
    static func buildRecord(for recordID: CKRecord.ID, in context: ModelContext) -> CKRecord? {
        guard let syncId = UUID(uuidString: recordID.recordName) else { return nil }

        if let model = Library.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = Document.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = Block.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = Tag.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = DocumentTag.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = Notebook.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = DocumentNotebook.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = TaskItem.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = Property.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = DocumentProperty.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = TemplateGroup.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = NoteTemplate.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = NotebookTemplateGroup.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = JournalTemplateGroup.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = SavedView.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = Attachment.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = CanvasBoard.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = CanvasCard.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = CanvasConnector.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        if let model = Plugin.fetch(syncId: syncId, in: context) { return model.makeCKRecord(in: context) }
        return nil
    }

    /// Upserts an incoming record into the matching local table, keyed by `record.recordType`.
    static func applyIncoming(_ record: CKRecord, in context: ModelContext) {
        switch record.recordType {
        case Library.ckRecordType: Library.upsert(from: record, in: context)
        case Document.ckRecordType: Document.upsert(from: record, in: context)
        case Block.ckRecordType: Block.upsert(from: record, in: context)
        case Tag.ckRecordType: Tag.upsert(from: record, in: context)
        case DocumentTag.ckRecordType: DocumentTag.upsert(from: record, in: context)
        case Notebook.ckRecordType: Notebook.upsert(from: record, in: context)
        case DocumentNotebook.ckRecordType: DocumentNotebook.upsert(from: record, in: context)
        case TaskItem.ckRecordType: TaskItem.upsert(from: record, in: context)
        case Property.ckRecordType: Property.upsert(from: record, in: context)
        case DocumentProperty.ckRecordType: DocumentProperty.upsert(from: record, in: context)
        case TemplateGroup.ckRecordType: TemplateGroup.upsert(from: record, in: context)
        case NoteTemplate.ckRecordType: NoteTemplate.upsert(from: record, in: context)
        case NotebookTemplateGroup.ckRecordType: NotebookTemplateGroup.upsert(from: record, in: context)
        case JournalTemplateGroup.ckRecordType: JournalTemplateGroup.upsert(from: record, in: context)
        case SavedView.ckRecordType: SavedView.upsert(from: record, in: context)
        case Attachment.ckRecordType: Attachment.upsert(from: record, in: context)
        case CanvasBoard.ckRecordType: CanvasBoard.upsert(from: record, in: context)
        case CanvasCard.ckRecordType: CanvasCard.upsert(from: record, in: context)
        case CanvasConnector.ckRecordType: CanvasConnector.upsert(from: record, in: context)
        case Plugin.ckRecordType: Plugin.upsert(from: record, in: context)
        default: break
        }
    }

    /// A record deleted server-side (rare — the app's own writes are soft-deletes, which
    /// arrive as ordinary field-updated records, not CloudKit deletions) mirrors as a local
    /// soft-delete rather than removing the row, matching every DAL's existing convention.
    static func applyDeletion(recordID: CKRecord.ID, recordType: String, in context: ModelContext) {
        guard let syncId = UUID(uuidString: recordID.recordName) else { return }
        switch recordType {
        case Library.ckRecordType: Library.fetch(syncId: syncId, in: context)?.isActive = false
        case Document.ckRecordType: Document.fetch(syncId: syncId, in: context)?.isActive = false
        case Block.ckRecordType: Block.fetch(syncId: syncId, in: context)?.isActive = false
        case Tag.ckRecordType: Tag.fetch(syncId: syncId, in: context)?.isActive = false
        case DocumentTag.ckRecordType: DocumentTag.fetch(syncId: syncId, in: context)?.isActive = false
        case Notebook.ckRecordType: Notebook.fetch(syncId: syncId, in: context)?.isActive = false
        case DocumentNotebook.ckRecordType: DocumentNotebook.fetch(syncId: syncId, in: context)?.isActive = false
        case TaskItem.ckRecordType: TaskItem.fetch(syncId: syncId, in: context)?.isActive = false
        case Property.ckRecordType: Property.fetch(syncId: syncId, in: context)?.isActive = false
        case DocumentProperty.ckRecordType: DocumentProperty.fetch(syncId: syncId, in: context)?.isActive = false
        case TemplateGroup.ckRecordType: TemplateGroup.fetch(syncId: syncId, in: context)?.isActive = false
        case NoteTemplate.ckRecordType: NoteTemplate.fetch(syncId: syncId, in: context)?.isActive = false
        case NotebookTemplateGroup.ckRecordType: NotebookTemplateGroup.fetch(syncId: syncId, in: context)?.isActive = false
        case JournalTemplateGroup.ckRecordType: JournalTemplateGroup.fetch(syncId: syncId, in: context)?.isActive = false
        case SavedView.ckRecordType: SavedView.fetch(syncId: syncId, in: context)?.isActive = false
        case Attachment.ckRecordType: Attachment.fetch(syncId: syncId, in: context)?.isActive = false
        case CanvasBoard.ckRecordType: CanvasBoard.fetch(syncId: syncId, in: context)?.isActive = false
        case CanvasCard.ckRecordType: CanvasCard.fetch(syncId: syncId, in: context)?.isActive = false
        case CanvasConnector.ckRecordType: CanvasConnector.fetch(syncId: syncId, in: context)?.isActive = false
        case Plugin.ckRecordType: Plugin.fetch(syncId: syncId, in: context)?.isActive = false
        default: break
        }
    }

}
