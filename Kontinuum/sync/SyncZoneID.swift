// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncZoneID.swift
//  Kontinuum
//

import CloudKit
import Foundation

/// One custom `CKRecordZone` per `Library` — the default zone is unused. Deterministic and
/// idempotent: the same `libraryId` always derives the same zone, so re-requesting a zone's
/// creation (e.g. on every launch, for every active library) is always safe to repeat.
///
/// `ownerName` defaults to `CKCurrentUserDefaultName` — correct for every library this device
/// owns (the overwhelming majority of calls). A library shared *to* this device (Phase 10) lives
/// in a zone owned by whoever shared it, not this account — `SharedLibraryRegistry` is what
/// supplies that real owner name for those calls.
extension CKRecordZone.ID {

    static func library(_ libraryId: UUID, ownerName: String = CKCurrentUserDefaultName) -> CKRecordZone.ID {
        CKRecordZone.ID(zoneName: "library-\(libraryId.uuidString)", ownerName: ownerName)
    }

}

extension CKRecord.ID {

    static func record(syncId: UUID, zoneID: CKRecordZone.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: syncId.uuidString, zoneID: zoneID)
    }

}
