// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictResolver.swift
//  NoteBytez
//

import CloudKit
import Foundation

/// What the user (or an automatic strategy) decided for a conflict. `.keepBoth` only makes
/// sense for `Document` (there's content worth duplicating); `ConflictResolver` degrades it to
/// `.keepServer` for every other model type, and `SyncEngine.resolveConflict` is what actually
/// creates the duplicate document for `.keepBoth`.
nonisolated enum ConflictResolutionChoice: Equatable {
    case keepClient
    case keepServer
    case keepBoth
    case merged(content: String)
}

/// Pure logic only — deciding what the resolved `CKRecord` should look like. No network, no
/// `ModelContext`; `SyncEngine.resolveConflict` is what actually saves the result and applies
/// it locally. Kept separate so this half (the part with real decisions to get right) is fully
/// unit-testable without a live CloudKit account, same split as `SyncRecordFactory`/`SyncEngine`
/// in Phase 12.
enum ConflictResolver {

    /// The record to save, given `choice`. Always builds on `conflict.serverRecord` — it's the
    /// one carrying the current, correct `recordChangeTag`; re-saving a freshly-constructed or
    /// stale-tagged record would just trigger the same `.serverRecordChanged` conflict again.
    static func resolvedRecord(for conflict: Conflict, choice: ConflictResolutionChoice) -> CKRecord {
        switch choice {
        case .keepClient:
            return mergingFields(from: conflict.clientRecord, onto: conflict.serverRecord)
        case .keepServer, .keepBoth:
            return conflict.serverRecord
        case .merged(let content):
            // Non-text fields fall back to whichever revision is newer — "last-write-wins for
            // non-text", per this phase's own plan wording.
            let base = lastWriteWinsChoice(for: conflict) == .keepClient ? conflict.clientRecord : conflict.serverRecord
            let record = mergingFields(from: base, onto: conflict.serverRecord)
            record["content"] = content
            return record
        }
    }

    /// Strategy 2 — whichever revision has the later `updatedOn` wins. Ties favor the client
    /// (the device mid-sync right now), matching the intuition that your own just-made edit
    /// should survive an exact-timestamp coincidence.
    static func lastWriteWinsChoice(for conflict: Conflict) -> ConflictResolutionChoice {
        let clientDate = conflict.clientRecord["updatedOn"] as? Date ?? .distantPast
        let serverDate = conflict.serverRecord["updatedOn"] as? Date ?? .distantPast
        return clientDate >= serverDate ? .keepClient : .keepServer
    }

    /// A copy of `destinationTemplate` (never mutates `conflict.serverRecord` in place — it may
    /// still be displayed or reused elsewhere) with every field from `source` written over it.
    private static func mergingFields(from source: CKRecord, onto destinationTemplate: CKRecord) -> CKRecord {
        guard let destination = destinationTemplate.copy() as? CKRecord else { return destinationTemplate }
        for key in source.allKeys() {
            destination[key] = source[key]
        }
        return destination
    }

}
