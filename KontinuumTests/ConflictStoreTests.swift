// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictStoreTests.swift
//  KontinuumTests
//

import Testing
import CloudKit
import Foundation
@testable import Kontinuum

/// Each test constructs its own `ConflictStore()` (not `.shared`), matching the isolation
/// pattern already established for `SyncStatusStoreTests`.
struct ConflictStoreTests {

    private func makeConflict(syncId: UUID = UUID(), title: String = "Roadmap") -> Conflict {
        let libraryId = UUID()
        let zoneID = CKRecordZone.ID.library(libraryId)
        let recordID = CKRecord.ID.record(syncId: syncId, zoneID: zoneID)
        let client = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
        let server = CKRecord(recordType: Document.ckRecordType, recordID: recordID)

        return Conflict(
            recordType: Document.ckRecordType,
            syncId: syncId,
            libraryId: libraryId,
            title: title,
            clientRecord: client,
            serverRecord: server,
            ancestorRecord: nil,
            detectedOn: Date()
        )
    }

    @Test func queueAddsAConflict() {
        let store = ConflictStore()
        store.queue(makeConflict())
        #expect(store.conflicts.count == 1)
    }

    @Test func queueingTheSameRecordAgainReplacesRatherThanDuplicates() {
        let store = ConflictStore()
        let syncId = UUID()
        store.queue(makeConflict(syncId: syncId, title: "First Capture"))
        store.queue(makeConflict(syncId: syncId, title: "Second Capture"))

        #expect(store.conflicts.count == 1)
        #expect(store.conflicts.first?.title == "Second Capture")
    }

    @Test func removeDropsTheMatchingConflict() {
        let store = ConflictStore()
        let conflict = makeConflict()
        store.queue(conflict)
        store.remove(conflict)

        #expect(store.conflicts.isEmpty)
    }

    @Test func conflictLookupBySyncId() {
        let store = ConflictStore()
        let syncId = UUID()
        store.queue(makeConflict(syncId: syncId))

        #expect(store.conflict(syncId: syncId) != nil)
        #expect(store.conflict(syncId: UUID()) == nil)
    }

    @Test func autoResolutionRecordAndClear() {
        let store = ConflictStore()
        let conflict = makeConflict()
        let resolution = ConflictAutoResolution(conflict: conflict, kept: .keepClient, keptLabel: "this device's edit")

        store.recordAutoResolution(resolution)
        #expect(store.autoResolution(syncId: conflict.syncId) != nil)

        store.clearAutoResolution(syncId: conflict.syncId)
        #expect(store.autoResolution(syncId: conflict.syncId) == nil)
    }

}
