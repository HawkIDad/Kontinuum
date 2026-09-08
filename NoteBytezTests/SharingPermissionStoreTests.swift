// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SharingPermissionStoreTests.swift
//  NoteBytezTests
//

import Testing
import CloudKit
import Foundation
@testable import NoteBytez

/// Each test constructs its own `SharingPermissionStore()` rather than using `.shared` —
/// mirrors `SyncStatusStoreTests`'s isolation rationale. `update(forLibraryId:share:)` itself
/// needs a real `CKShare` with a populated `currentUserParticipant`/`participants`, which can't
/// be fabricated outside a live CloudKit round-trip (same class of gap `ConflictResolverTests`
/// already accepts for `lastModifiedUserRecordID`) — covered here instead via the test-only
/// `setPermission` seam, which exercises exactly the enforcement logic
/// `SyncEngine.recordChanged` actually depends on.
struct SharingPermissionStoreTests {

    @Test func aLibraryWithNoCachedShareIsWritableByDefault() {
        let store = SharingPermissionStore()
        #expect(store.canWrite(toLibraryId: UUID()))
        #expect(store.isShared(UUID()) == false)
    }

    @Test func readOnlyPermissionMakesTheLibraryUnwritable() {
        let store = SharingPermissionStore()
        let libraryId = UUID()
        store.setPermission(.readOnly, forLibraryId: libraryId)

        #expect(store.canWrite(toLibraryId: libraryId) == false)
        #expect(store.isShared(libraryId))
    }

    @Test func readWritePermissionKeepsTheLibraryWritable() {
        let store = SharingPermissionStore()
        let libraryId = UUID()
        store.setPermission(.readWrite, forLibraryId: libraryId)

        #expect(store.canWrite(toLibraryId: libraryId))
    }

    @Test func permissionsAreTrackedIndependentlyPerLibrary() {
        let store = SharingPermissionStore()
        let readOnlyLibraryId = UUID()
        let readWriteLibraryId = UUID()
        store.setPermission(.readOnly, forLibraryId: readOnlyLibraryId)
        store.setPermission(.readWrite, forLibraryId: readWriteLibraryId)

        #expect(store.canWrite(toLibraryId: readOnlyLibraryId) == false)
        #expect(store.canWrite(toLibraryId: readWriteLibraryId))
    }

    @Test func updateWithNilShareClearsAPreviouslyCachedPermission() {
        let store = SharingPermissionStore()
        let libraryId = UUID()
        store.setPermission(.readOnly, forLibraryId: libraryId)
        store.update(forLibraryId: libraryId, share: nil)

        #expect(store.isShared(libraryId) == false)
        #expect(store.canWrite(toLibraryId: libraryId))
    }

    @Test func displayNameIsNilForAnUnknownParticipant() {
        let store = SharingPermissionStore()
        #expect(store.displayName(forUserRecordID: CKRecord.ID(recordName: "unknown")) == nil)
    }

}
