// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncableRecord.swift
//  NoteBytez
//

import CloudKit
import Foundation
import SwiftData

/// Lets `SyncEngine` map any of the app's 8 synced models to/from a `CKRecord` generically,
/// instead of hand-writing per-model dispatch inside the engine itself. Every model already
/// conforms to `Codable` with its own `CodingKeys`, so `writeFields`/`readFields` mirror that
/// same field list — see each model's `+Sync.swift` extension.
protocol SyncableRecord: PersistentModel {

    static var ckRecordType: String { get }

    /// The model's own `{model}Id` — reused verbatim as `CKRecord.ID.recordName`, per Phase 12.
    var syncId: UUID? { get }

    /// Every model already declares these exact fields (`ARCHITECTURE.md`'s Model Conventions'
    /// audit-field convention) — surfacing them here costs each conformer nothing, and lets
    /// `SyncEngine.recordChanged` populate them generically (Phase 10) instead of touching every
    /// DAL's create/update call sites individually.
    var createdBy: String? { get set }
    var updatedBy: String? { get set }

    /// The owning library's ID, used to place this record in that library's zone and to set
    /// its `library` reference field. Most models carry `libraryId` directly; `Block` (which
    /// only carries `documentId`) resolves it via its parent `Document`.
    func resolvedLibraryId(in context: ModelContext) -> UUID?

    func writeFields(to record: CKRecord)
    func readFields(from record: CKRecord)

    static func fetch(syncId: UUID, in context: ModelContext) -> Self?

    /// A freshly-inserted, otherwise-empty instance carrying only `syncId` — immediately
    /// overwritten by `readFields(from:)` when a record arrives for a model we don't have
    /// locally yet. Placeholder constructor args are fine since every stored property is a
    /// settable `var` that gets replaced right after.
    static func makePlaceholder(syncId: UUID, in context: ModelContext) -> Self

}

extension SyncableRecord {

    /// Builds this model's current `CKRecord` for upload: recordType/recordID per Phase 12's
    /// scheme, own fields, and (for every model except `Library` itself) a `library` reference
    /// field pointing at the zone's root Library record.
    func makeCKRecord(in context: ModelContext) -> CKRecord? {
        guard let syncId, let libraryId = resolvedLibraryId(in: context) else { return nil }
        let zoneID = CKRecordZone.ID.library(libraryId, ownerName: SharedLibraryRegistry.shared.ownerName(forLibraryId: libraryId) ?? CKCurrentUserDefaultName)
        let record = CKRecord(recordType: Self.ckRecordType, recordID: .record(syncId: syncId, zoneID: zoneID))
        writeFields(to: record)

        if syncId != libraryId {
            let libraryRecordID = CKRecord.ID.record(syncId: libraryId, zoneID: zoneID)
            let reference = CKRecord.Reference(recordID: libraryRecordID, action: .none)
            record["library"] = reference
            // Also the record's actual `.parent` (a distinct property CloudKit sharing reads,
            // not just any reference field with the same target) — Phase 10's CKShare, rooted
            // at the Library record, automatically covers every record whose parent chain leads
            // up to it. Same reference, no extra fetch.
            record.parent = reference
        }
        return record
    }

    /// Upserts the local model from an incoming `CKRecord`: updates it in place if we already
    /// have a row for this `syncId`, otherwise inserts a new placeholder first.
    @discardableResult
    static func upsert(from record: CKRecord, in context: ModelContext) -> Self? {
        guard let syncId = UUID(uuidString: record.recordID.recordName) else { return nil }
        let model = fetch(syncId: syncId, in: context) ?? makePlaceholder(syncId: syncId, in: context)
        model.readFields(from: record)
        return model
    }

}
