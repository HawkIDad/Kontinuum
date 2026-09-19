// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncStatusStoreTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

/// Each test constructs its own `SyncStatusStore()` rather than using `.shared` — a fresh
/// instance never calls `startMonitoringNetwork()`, so `isOffline` stays deterministically
/// `false` and these tests never depend on the test runner's real network state.
struct SyncStatusStoreTests {

    @Test func initialStatusIsSynced() {
        let store = SyncStatusStore()
        #expect(store.status == .synced)
    }

    @Test func syncWillStartTransitionsToSyncing() {
        let store = SyncStatusStore()
        store.syncWillStart()
        #expect(store.status == .syncing)
    }

    /// A conflict discovered mid-sync doesn't preempt the in-flight spinner — `.syncing` still
    /// wins until the sync pass actually finishes, matching real `CKSyncEngine` event order
    /// (`.sentRecordZoneChanges` with a conflict, then `.didSendChanges`).
    @Test func conflictDuringAnInFlightSyncStaysSyncingUntilItFinishes() {
        let store = SyncStatusStore()
        store.syncWillStart()
        store.recordConflict(noteTitle: "Roadmap")

        #expect(store.status == .syncing)
    }

    /// The full sequence this phase's plan calls out by name.
    @Test func stateTransitionsThroughSyncedSyncingConflictSynced() {
        let store = SyncStatusStore()
        #expect(store.status == .synced)

        store.syncWillStart()
        #expect(store.status == .syncing)

        store.recordConflict(noteTitle: "NoteBytez Roadmap")
        store.syncDidFinish()
        #expect(store.status == .conflict)

        store.decrementConflictCount()
        #expect(store.status == .synced)
    }

    @Test func conflictHeadlineCountReflectsMultipleUnresolvedConflicts() {
        let store = SyncStatusStore()
        store.recordConflict(noteTitle: "Roadmap")
        store.recordConflict(noteTitle: "Weekly Review")

        #expect(store.conflictCount == 2)
        #expect(store.status == .conflict)
    }

    @Test func syncDidFinishUpdatesLastSyncedOnAndClearsSyncingFlag() {
        let store = SyncStatusStore()
        store.syncWillStart()
        store.syncDidFinish()

        #expect(store.isSyncing == false)
        #expect(store.lastSyncedOn != nil)
    }

    @Test func recordSyncedNotesIsANoOpForZeroCount() {
        let store = SyncStatusStore()
        store.recordSyncedNotes(count: 0, received: false)
        #expect(store.logEntries.isEmpty)
    }

    @Test func recordSyncedNotesAppendsADescriptiveLogEntry() {
        let store = SyncStatusStore()
        store.recordSyncedNotes(count: 3, received: false)

        let entry = try! #require(store.logEntries.first)
        #expect(entry.message == "Synced — 3 notes updated")
        #expect(entry.isError == false)
    }

    @Test func recordSyncedNotesUsesSingularNounForOne() {
        let store = SyncStatusStore()
        store.recordSyncedNotes(count: 1, received: true)

        #expect(store.logEntries.first?.message == "Synced — 1 note received")
    }

    @Test func recordConflictAppendsAnErrorFlaggedLogEntry() {
        let store = SyncStatusStore()
        store.recordConflict(noteTitle: "Roadmap")

        let entry = try! #require(store.logEntries.first)
        #expect(entry.isError == true)
        #expect(entry.message.contains("Roadmap"))
    }

    // MARK: - Manual resolution logging + count (20260910v1-Sync.md SF 6 / SF 7 / SF 9)

    @Test func recordManualResolutionLogsAnAttributedNonErrorEntry() {
        let store = SyncStatusStore()
        store.recordManualResolution(title: "Draft Proposal", summary: "kept Dana's version")

        let entry = try! #require(store.logEntries.first)
        #expect(entry.isError == false)
        #expect(entry.message == "Resolved — \"Draft Proposal\" — kept Dana's version")
    }

    @Test func recordResolutionUndoneLogsANonErrorEntry() {
        let store = SyncStatusStore()
        store.recordResolutionUndone(title: "Draft Proposal")

        #expect(store.logEntries.first?.message == "Resolution undone — \"Draft Proposal\"")
        #expect(store.logEntries.first?.isError == false)
    }

    @Test func incrementConflictCountRestoresTheConflictStatusAfterAnUndo() {
        let store = SyncStatusStore()
        store.recordConflict(noteTitle: "Roadmap")
        store.decrementConflictCount()
        #expect(store.status == .synced)

        store.incrementConflictCount()
        #expect(store.conflictCount == 1)
        #expect(store.status == .conflict)
    }

    @Test func recordErrorSetsADismissibleErrorAndAppendsToTheLog() {
        let store = SyncStatusStore()
        store.recordError("Network unavailable")

        #expect(store.dismissibleError?.message == "Network unavailable")
        #expect(store.logEntries.first?.message == "Network unavailable")
    }

    @Test func dismissErrorClearsTheBannerButKeepsTheLogEntry() {
        let store = SyncStatusStore()
        store.recordError("Network unavailable")
        store.dismissError()

        #expect(store.dismissibleError == nil)
        #expect(store.logEntries.first?.message == "Network unavailable")
    }

    @Test func logIsCappedAtFiftyEntriesMostRecentFirst() {
        let store = SyncStatusStore()
        for index in 1...60 {
            store.recordSyncedNotes(count: index, received: false)
        }

        #expect(store.logEntries.count == 50)
        #expect(store.logEntries.first?.message == "Synced — 60 notes updated")
    }

}
