// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Conflict.swift
//  Kontinuum
//

import CloudKit
import Foundation

/// One side of a conflict — "revision", not "device": CloudKit's private database doesn't
/// expose which physical device wrote the server's current version, only that it isn't the
/// version this device tried to save. Modeling it this way (rather than hard-coding "this Mac
/// vs. this iPhone") is what lets V1's multi-user conflicts extend this later without a
/// rewrite, per this phase's own Decisions Log note.
struct ConflictRevision: Identifiable {

    /// `nonisolated`: a plain case-only enum, opted out of this target's
    /// `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — otherwise its implicitly-synthesized
    /// `Equatable` conformance is itself MainActor-isolated, which test assertions
    /// (`#expect(a == b)`, generated as nonisolated code) can't call into (a warning today, a
    /// Swift 6 language-mode error).
    nonisolated enum Kind {
        case client
        case server
    }

    let id = UUID()
    let kind: Kind
    let timestamp: Date?
    let snippet: String
    /// Phase 10 — a named collaborator, when CloudKit sharing makes one resolvable (see
    /// `Conflict.revisions` below), extending this already-revision-based model rather than
    /// rewriting it into a device/user-keyed one. `nil` on `.client` (this device's own attempt
    /// is never worth attributing to a "collaborator") and on any pre-Phase-10 single-user
    /// conflict, where `label` reads exactly as it always has.
    let collaboratorName: String?

    var label: String {
        let base: String
        switch kind {
        case .client: return "This Device"
        case .server: base = "Synced Elsewhere"
        }
        guard let collaboratorName, !collaboratorName.isEmpty else { return base }
        return "\(base) — \(collaboratorName)"
    }

}

/// A `CKSyncEngine`-reported `.serverRecordChanged` failure, captured in full (not just logged)
/// so S10 can actually resolve it. `clientRecord` is what this device tried to save;
/// `serverRecord` is CloudKit's current version (and the one carrying the change tag any
/// resolution must build on — see `ConflictResolver`); `ancestorRecord`, when CloudKit
/// provides one, is the last version both sides agreed on.
struct Conflict: Identifiable {

    let id = UUID()
    let recordType: String
    let syncId: UUID
    let libraryId: UUID
    let title: String
    let clientRecord: CKRecord
    let serverRecord: CKRecord
    let ancestorRecord: CKRecord?
    let detectedOn: Date

    /// Both fields absent (client's own field, since it's the record type's canonical field
    /// when present) means this model type has no meaningful text to diff — `ConflictResolver`
    /// and S10 use this to fall back to last-write-wins for non-`Document` conflicts.
    var hasDiffableContent: Bool {
        clientRecord["content"] is String && serverRecord["content"] is String
    }

    var revisions: [ConflictRevision] {
        [
            ConflictRevision(kind: .client, timestamp: clientRecord["updatedOn"] as? Date, snippet: Self.snippet(for: clientRecord), collaboratorName: nil),
            ConflictRevision(kind: .server, timestamp: serverRecord["updatedOn"] as? Date, snippet: Self.snippet(for: serverRecord), collaboratorName: Self.collaboratorName(for: serverRecord))
        ]
    }

    private static func snippet(for record: CKRecord) -> String {
        (record["content"] as? String) ?? (record["name"] as? String) ?? (record["title"] as? String) ?? ""
    }

    /// `lastModifiedUserRecordID` is only ever populated on a `CKRecord` CloudKit itself handed
    /// back (a fetched/saved record) — locally-constructed records (every test fixture in
    /// `ConflictResolverTests`) leave it `nil`, so this — and therefore `label` — is unaffected
    /// outside a real, shared, multi-user CloudKit context.
    private static func collaboratorName(for record: CKRecord) -> String? {
        guard let userRecordID = record.lastModifiedUserRecordID else { return nil }
        return SharingPermissionStore.shared.displayName(forUserRecordID: userRecordID)
    }

    static func displayTitle(for record: CKRecord) -> String {
        (record["title"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            ?? (record["name"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            ?? record.recordType
    }

}
