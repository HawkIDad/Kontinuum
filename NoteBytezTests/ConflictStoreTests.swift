// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictStoreTests.swift
//  NoteBytezTests
//

import Testing
import CloudKit
import Foundation
@testable import NoteBytez

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

    // MARK: - Manual-resolution acknowledgement + undo (20260910v1-Sync.md SF 4 / SF 7)

    @Test func recordResolutionOpensBothTheAckAndTheUndoWindow() {
        let store = ConflictStore()
        let conflict = makeConflict(title: "Draft Proposal")

        store.recordResolution(of: conflict, choice: .keepClient)

        #expect(store.recentlyResolved[conflict.syncId]?.summary == "kept this device's edit")
        #expect(store.pendingUndo?.conflict.syncId == conflict.syncId)
        #expect(store.pendingUndo?.choice == .keepClient)
    }

    @Test func clearAcknowledgementRemovesOnlyTheAck() {
        let store = ConflictStore()
        let conflict = makeConflict()
        store.recordResolution(of: conflict, choice: .keepServer)

        store.clearAcknowledgement(syncId: conflict.syncId)

        #expect(store.recentlyResolved[conflict.syncId] == nil)
        #expect(store.pendingUndo != nil)
    }

    @Test func clearUndoRemovesOnlyThePendingUndo() {
        let store = ConflictStore()
        let conflict = makeConflict()
        store.recordResolution(of: conflict, choice: .keepBoth)

        store.clearUndo()

        #expect(store.pendingUndo == nil)
        #expect(store.recentlyResolved[conflict.syncId] != nil)
    }

    @Test func theAcknowledgementExpiresOnItsOwnAfterTheConfiguredDuration() async {
        let store = ConflictStore(acknowledgementDuration: .milliseconds(50), undoWindow: .seconds(30))
        let conflict = makeConflict()
        store.recordResolution(of: conflict, choice: .keepClient)
        #expect(store.recentlyResolved[conflict.syncId] != nil)

        try? await Task.sleep(for: .milliseconds(250))
        #expect(store.recentlyResolved[conflict.syncId] == nil)
        #expect(store.pendingUndo != nil, "the longer undo window is unaffected")
    }

    @Test func theUndoWindowLapsesOnItsOwnAfterTheConfiguredDuration() async {
        let store = ConflictStore(acknowledgementDuration: .seconds(30), undoWindow: .milliseconds(50))
        store.recordResolution(of: makeConflict(), choice: .keepClient)
        #expect(store.pendingUndo != nil)

        try? await Task.sleep(for: .milliseconds(250))
        #expect(store.pendingUndo == nil)
    }

}
