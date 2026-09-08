// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SharingPermissionStore.swift
//  NoteBytez
//

import CloudKit
import Foundation
import Observation

/// This device's cached view of "what am I allowed to do in each shared Library" plus "who are
/// the other participants" — local-only (never synced, never a SwiftData model), refreshed
/// whenever `SharingService` fetches or updates a `CKShare`.
///
/// Read by two very different call sites: `SyncEngine.recordChanged` (a plain synchronous
/// `canWrite` check, the actual read-only-participant-write-rejection enforcement point) and
/// `Conflict.revisions` (a synchronous display-name lookup for a conflicting revision's
/// `lastModifiedUserRecordID`). Neither can await a network call, which is exactly why this
/// exists as a cache rather than a pass-through to `SharingService`.
@Observable
final class SharingPermissionStore {

    static let shared = SharingPermissionStore()

    private(set) var permissionsByLibraryId: [UUID: CKShare.ParticipantPermission] = [:]
    private(set) var participantNamesByUserRecordID: [CKRecord.ID: String] = [:]

    init() {}

    /// A library with no cached share (never shared, or not yet refreshed) is always writable —
    /// sharing is opt-in, and an owner's own unshared library must never be treated as
    /// read-only by default.
    func canWrite(toLibraryId libraryId: UUID) -> Bool {
        (permissionsByLibraryId[libraryId] ?? .readWrite) != .readOnly
    }

    func isShared(_ libraryId: UUID) -> Bool {
        permissionsByLibraryId[libraryId] != nil
    }

    /// Called by `SharingService` after creating, fetching, or updating a share — records this
    /// device's own permission plus every participant's display name in one pass. `share == nil`
    /// means "no longer shared" (owner stopped sharing), clearing the cached permission so
    /// `canWrite` falls back to its unshared-library default.
    func update(forLibraryId libraryId: UUID, share: CKShare?) {
        guard let share else {
            permissionsByLibraryId[libraryId] = nil
            return
        }

        permissionsByLibraryId[libraryId] = share.currentUserParticipant?.permission ?? .readWrite
        for participant in share.participants {
            guard let userRecordID = participant.userIdentity.userRecordID,
                  let name = Self.displayName(for: participant.userIdentity) else { continue }
            participantNamesByUserRecordID[userRecordID] = name
        }
    }

    func displayName(forUserRecordID userRecordID: CKRecord.ID) -> String? {
        participantNamesByUserRecordID[userRecordID]
    }

    /// Test seam — lets a test exercise `canWrite`'s enforcement logic without a real `CKShare`
    /// (which can't be fabricated with a populated `currentUserParticipant` outside a live
    /// CloudKit round-trip).
    func setPermission(_ permission: CKShare.ParticipantPermission, forLibraryId libraryId: UUID) {
        permissionsByLibraryId[libraryId] = permission
    }

    private static func displayName(for identity: CKUserIdentity) -> String? {
        if let nameComponents = identity.nameComponents {
            let formatted = PersonNameComponentsFormatter().string(from: nameComponents)
            if !formatted.isEmpty { return formatted }
        }
        return identity.lookupInfo?.emailAddress
    }

}
