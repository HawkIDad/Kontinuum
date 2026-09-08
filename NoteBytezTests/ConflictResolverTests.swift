// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictResolverTests.swift
//  NoteBytezTests
//

import Testing
import CloudKit
import Foundation
@testable import NoteBytez

/// Covers `ConflictResolver`'s pure record-merging decisions — no network, no `ModelContext`,
/// same "compiled + unit-tested" scope as the rest of `sync/` that doesn't need a live
/// CloudKit account (see Phase 12/13's notes).
struct ConflictResolverTests {

    private func makeConflict(
        clientContent: String = "client content",
        serverContent: String = "server content",
        clientUpdatedOn: Date = Date(timeIntervalSince1970: 1000),
        serverUpdatedOn: Date = Date(timeIntervalSince1970: 500)
    ) -> Conflict {
        let libraryId = UUID()
        let syncId = UUID()
        let zoneID = CKRecordZone.ID.library(libraryId)
        let recordID = CKRecord.ID.record(syncId: syncId, zoneID: zoneID)

        let client = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
        client["title"] = "Roadmap"
        client["content"] = clientContent
        client["updatedOn"] = clientUpdatedOn
        client["isActive"] = true

        let server = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
        server["title"] = "Roadmap"
        server["content"] = serverContent
        server["updatedOn"] = serverUpdatedOn
        server["isActive"] = true

        return Conflict(
            recordType: Document.ckRecordType,
            syncId: syncId,
            libraryId: libraryId,
            title: "Roadmap",
            clientRecord: client,
            serverRecord: server,
            ancestorRecord: nil,
            detectedOn: Date()
        )
    }

    @Test func keepClientCopiesClientFieldsOntoAServerRecordCopy() {
        let conflict = makeConflict()
        let resolved = ConflictResolver.resolvedRecord(for: conflict, choice: .keepClient)

        #expect(resolved["content"] as? String == "client content")
        #expect(resolved.recordID == conflict.serverRecord.recordID)
    }

    @Test func keepClientNeverMutatesTheOriginalServerRecord() {
        let conflict = makeConflict()
        _ = ConflictResolver.resolvedRecord(for: conflict, choice: .keepClient)

        #expect(conflict.serverRecord["content"] as? String == "server content")
    }

    @Test func keepServerReturnsTheServerRecordAsIs() {
        let conflict = makeConflict()
        let resolved = ConflictResolver.resolvedRecord(for: conflict, choice: .keepServer)

        #expect(resolved["content"] as? String == "server content")
    }

    @Test func keepBothAlsoResolvesToTheServerRecord() {
        // The literal duplicate document is created by `SyncEngine.resolveConflict`, not here —
        // this only confirms the *original* record resolves the same way `.keepServer` does.
        let conflict = makeConflict()
        let resolved = ConflictResolver.resolvedRecord(for: conflict, choice: .keepBoth)

        #expect(resolved["content"] as? String == "server content")
    }

    @Test func mergedChoiceOverridesOnlyContent() {
        let conflict = makeConflict()
        let resolved = ConflictResolver.resolvedRecord(for: conflict, choice: .merged(content: "merged result"))

        #expect(resolved["content"] as? String == "merged result")
        #expect(resolved["title"] as? String == "Roadmap")
    }

    @Test func lastWriteWinsFavorsTheNewerClientEdit() {
        let conflict = makeConflict(clientUpdatedOn: Date(timeIntervalSince1970: 2000), serverUpdatedOn: Date(timeIntervalSince1970: 1000))
        #expect(ConflictResolver.lastWriteWinsChoice(for: conflict) == .keepClient)
    }

    @Test func lastWriteWinsFavorsTheNewerServerEdit() {
        let conflict = makeConflict(clientUpdatedOn: Date(timeIntervalSince1970: 1000), serverUpdatedOn: Date(timeIntervalSince1970: 2000))
        #expect(ConflictResolver.lastWriteWinsChoice(for: conflict) == .keepServer)
    }

    @Test func lastWriteWinsBreaksATieInFavorOfTheClient() {
        let sameInstant = Date(timeIntervalSince1970: 1500)
        let conflict = makeConflict(clientUpdatedOn: sameInstant, serverUpdatedOn: sameInstant)
        #expect(ConflictResolver.lastWriteWinsChoice(for: conflict) == .keepClient)
    }

    @Test func conflictReportsDiffableContentWhenBothSidesHaveText() {
        let conflict = makeConflict()
        #expect(conflict.hasDiffableContent)
    }

    @Test func conflictRevisionsAreLabeledByRevisionNotDevice() {
        let conflict = makeConflict()
        let labels = Set(conflict.revisions.map(\.label))
        #expect(labels == ["This Device", "Synced Elsewhere"])
    }

    /// Phase 10 — `lastModifiedUserRecordID` is only ever populated on a `CKRecord` CloudKit
    /// itself handed back, never on a locally-constructed one (every fixture in this file), so
    /// `collaboratorName` stays `nil` here and every conflict built by `makeConflict` keeps
    /// reading exactly as it did before this phase — real collaborator-name resolution against
    /// a live shared library isn't exercisable outside a real multi-account CloudKit round-trip.
    @Test func conflictRevisionsHaveNoCollaboratorNameOutsideALiveSharedLibrary() {
        let conflict = makeConflict()
        #expect(conflict.revisions.allSatisfy { $0.collaboratorName == nil })
    }

    /// `ConflictRevision.label`'s formatting is what Phase 10 actually added — fully testable by
    /// constructing the revision directly, independent of how `collaboratorName` gets resolved.
    @Test func revisionLabelAppendsTheCollaboratorNameWhenPresent() {
        let attributed = ConflictRevision(kind: .server, timestamp: nil, snippet: "", collaboratorName: "Dana Reyes")
        #expect(attributed.label == "Synced Elsewhere — Dana Reyes")

        let unattributed = ConflictRevision(kind: .server, timestamp: nil, snippet: "", collaboratorName: nil)
        #expect(unattributed.label == "Synced Elsewhere")
    }

    /// A `.client` revision is always "this device's own attempt" — never worth attributing to
    /// a named collaborator, even if one were somehow resolvable, per `ConflictRevision`'s own
    /// doc comment.
    @Test func clientRevisionLabelIgnoresAnyCollaboratorName() {
        let revision = ConflictRevision(kind: .client, timestamp: nil, snippet: "", collaboratorName: "Dana Reyes")
        #expect(revision.label == "This Device")
    }

    @Test func revisionLabelTreatsAnEmptyCollaboratorNameAsAbsent() {
        let revision = ConflictRevision(kind: .server, timestamp: nil, snippet: "", collaboratorName: "")
        #expect(revision.label == "Synced Elsewhere")
    }

    @Test func conflictReportsNoDiffableContentWhenAModelHasNoContentField() {
        let libraryId = UUID()
        let recordID = CKRecord.ID.record(syncId: UUID(), zoneID: .library(libraryId))
        let client = CKRecord(recordType: Notebook.ckRecordType, recordID: recordID)
        client["name"] = "Projects"
        let server = CKRecord(recordType: Notebook.ckRecordType, recordID: recordID)
        server["name"] = "Projects (renamed)"

        let conflict = Conflict(
            recordType: Notebook.ckRecordType, syncId: UUID(), libraryId: libraryId, title: "Projects",
            clientRecord: client, serverRecord: server, ancestorRecord: nil, detectedOn: Date()
        )
        #expect(conflict.hasDiffableContent == false)
    }

    @Test func displayTitlePrefersTitleThenNameThenRecordType() {
        let recordID = CKRecord.ID.record(syncId: UUID(), zoneID: .library(UUID()))

        let withTitle = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
        withTitle["title"] = "Roadmap"
        withTitle["name"] = "ignored"
        #expect(Conflict.displayTitle(for: withTitle) == "Roadmap")

        let withNameOnly = CKRecord(recordType: Notebook.ckRecordType, recordID: recordID)
        withNameOnly["name"] = "Projects"
        #expect(Conflict.displayTitle(for: withNameOnly) == "Projects")

        let withNeither = CKRecord(recordType: TaskItem.ckRecordType, recordID: recordID)
        #expect(Conflict.displayTitle(for: withNeither) == TaskItem.ckRecordType)

        let withEmptyTitle = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
        withEmptyTitle["title"] = ""
        withEmptyTitle["name"] = "Fallback"
        #expect(Conflict.displayTitle(for: withEmptyTitle) == "Fallback")
    }

}
