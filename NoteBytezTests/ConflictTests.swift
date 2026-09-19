// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictTests.swift
//  NoteBytezTests
//

import Testing
import CloudKit
import Foundation
@testable import NoteBytez

/// `Conflict.resolutionSummary(for:)` — the pure "which side was kept" phrasing for S9's
/// resolved-history log (`Docs/Bugs/20260910v1-Sync.md` SF 6). The named-collaborator branch is
/// exercised through the explicit-`collaboratorName` overload; the zero-argument form only ever
/// resolves a name from a live shared `CKRecord`, covered manually in Phase 5.
struct ConflictTests {

    private func makeConflict() -> Conflict {
        let libraryId = UUID()
        let syncId = UUID()
        let zoneID = CKRecordZone.ID.library(libraryId)
        let recordID = CKRecord.ID.record(syncId: syncId, zoneID: zoneID)
        return Conflict(
            recordType: Document.ckRecordType,
            syncId: syncId,
            libraryId: libraryId,
            title: "Draft Proposal",
            clientRecord: CKRecord(recordType: Document.ckRecordType, recordID: recordID),
            serverRecord: CKRecord(recordType: Document.ckRecordType, recordID: recordID),
            ancestorRecord: nil,
            detectedOn: Date()
        )
    }

    @Test func keepClientReadsAsThisDevicesEdit() {
        #expect(makeConflict().resolutionSummary(for: .keepClient) == "kept this device's edit")
    }

    @Test func keepServerNamesTheCollaboratorWhenOneResolves() {
        #expect(makeConflict().resolutionSummary(for: .keepServer, collaboratorName: "Dana") == "kept Dana's version")
    }

    @Test func keepServerFallsBackWhenNoCollaboratorName() {
        let conflict = makeConflict()
        #expect(conflict.resolutionSummary(for: .keepServer, collaboratorName: nil) == "kept the version synced elsewhere")
        #expect(conflict.resolutionSummary(for: .keepServer, collaboratorName: "") == "kept the version synced elsewhere")
    }

    @Test func keepServerFallsBackByDefaultForALocallyConstructedRecord() {
        // No `lastModifiedUserRecordID` on a record CloudKit never handed back.
        #expect(makeConflict().resolutionSummary(for: .keepServer) == "kept the version synced elsewhere")
    }

    @Test func keepBothAndMergedHaveTheirOwnPhrasing() {
        let conflict = makeConflict()
        #expect(conflict.resolutionSummary(for: .keepBoth) == "kept both versions")
        #expect(conflict.resolutionSummary(for: .merged(content: "merged body")) == "kept a merged version")
    }

}
