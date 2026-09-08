// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SharingService.swift
//  Kontinuum
//

import CloudKit
import Foundation
import OSLog

/// `CKShare` creation/participant management for CloudKit Sharing (V1 Phase 10). Lives in
/// `sync/` rather than `dal/` — it manages `CKShare`/`CKRecord` directly against the private
/// database, not a SwiftData model through `ModelContext` (mirrors where `ConflictResolver`/
/// `SyncEngine` already sit for the same reason).
///
/// Sharing is root-record based, per this phase's Decisions rationale: `Library` is already
/// each zone's root record (MVP Phase 12), and every other record already carries a `library`
/// `CKRecord.Reference` (`SyncableRecord.makeCKRecord`) — that reference is now also set as the
/// record's actual `.parent`, which is what lets a `CKShare` rooted at the `Library` record
/// automatically cover every record beneath it, with no schema change.
enum SharingError: LocalizedError {
    case notYetSynced
    case shareSaveFailed
    case noActiveShare
    case permissionUpdateFailed
    case invalidEmail
    case participantNotFound
    case alreadyParticipant

    var errorDescription: String? {
        switch self {
        case .notYetSynced: return "This library hasn't finished syncing yet — try again once sync completes."
        case .shareSaveFailed: return "Couldn't create the share."
        case .noActiveShare: return "This library isn't currently shared."
        case .permissionUpdateFailed: return "Couldn't update that participant's permission."
        case .invalidEmail: return "Enter a valid email address."
        case .participantNotFound: return "No Apple Account was found for that email address."
        case .alreadyParticipant: return "That person is already a participant on this library."
        }
    }
}

final class SharingService: @unchecked Sendable {

    static let shared = SharingService()

    private let logger = Log.logger(.sync)
    private lazy var database: CKDatabase = CKContainer(identifier: SyncEngine.containerIdentifier).privateCloudDatabase
    private lazy var container: CKContainer = CKContainer(identifier: SyncEngine.containerIdentifier)

    private init() {}

    var cloudKitContainer: CKContainer { container }

    /// Fetches the Library's current server-side record (so the save carries a valid change
    /// tag, rather than risking a `.serverRecordChanged` conflict with a freshly-built one),
    /// attaches a new `CKShare` to it, and saves both. Returns the share so the caller can
    /// present the native invite controller — this only establishes the share record itself,
    /// not the invite.
    func createShare(forLibraryId libraryId: UUID, libraryName: String) async throws -> CKShare {
        let rootRecordID = CKRecord.ID.record(syncId: libraryId, zoneID: .library(libraryId))
        let rootRecord: CKRecord
        do {
            rootRecord = try await database.record(for: rootRecordID)
        } catch {
            throw SharingError.notYetSynced
        }

        let share = CKShare(rootRecord: rootRecord)
        share[CKShare.SystemFieldKey.title] = libraryName as CKRecordValue
        share.publicPermission = .none

        let (saveResults, _) = try await database.modifyRecords(saving: [rootRecord, share], deleting: [])
        guard case .success(let savedRecord) = saveResults[share.recordID], let savedShare = savedRecord as? CKShare else {
            throw SharingError.shareSaveFailed
        }

        SharingPermissionStore.shared.update(forLibraryId: libraryId, share: savedShare)
        return savedShare
    }

    /// A deliberately loose local sanity check — non-empty local and domain parts either side of
    /// a single `@`, a dotted domain, no whitespace. Authoritative resolution is CloudKit's job
    /// (`addParticipant` below); this only avoids a pointless round trip and lets the S22 "Add"
    /// button disable itself instantly. Swift stdlib only — no regex dependency (CLAUDE.md §5).
    static func isValidEmailFormat(_ email: String) -> Bool {
        guard !email.isEmpty, !email.contains(where: \.isWhitespace) else { return false }
        let parts = email.split(separator: "@", omittingEmptySubsequences: false)
        guard parts.count == 2, let local = parts.first, let domain = parts.last else { return false }
        guard !local.isEmpty, !domain.isEmpty else { return false }
        return domain.contains(".") && !domain.hasPrefix(".") && !domain.hasSuffix(".")
    }

    /// Adds a participant to the library's share by Apple Account email, resolved entirely via
    /// CloudKit (`CKContainer.shareParticipant(forEmailAddress:)`) — no `UICloudSharingController`
    /// and no Mail/Messages compose step, so it works on a device with no mail account (a
    /// Simulator, a fresh device). Creates the share first if the library doesn't have one yet,
    /// exactly as the invite-controller path does. `publicPermission` is untouched — access
    /// stays per-invited-participant. See Docs/Plans/NoteBytez20260831v1-Sharing.md.
    func addParticipant(
        emailAddress: String,
        permission: CKShare.ParticipantPermission,
        forLibraryId libraryId: UUID,
        libraryName: String
    ) async throws {
        let trimmedEmail = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidEmailFormat(trimmedEmail) else { throw SharingError.invalidEmail }

        let share: CKShare
        if let existingShare = try await fetchShare(forLibraryId: libraryId) {
            share = existingShare
        } else {
            share = try await createShare(forLibraryId: libraryId, libraryName: libraryName)
        }

        let participant: CKShare.Participant
        do {
            participant = try await container.shareParticipant(forEmailAddress: trimmedEmail)
        } catch {
            logger.error("Couldn't resolve a share participant for the supplied email: \(error.localizedDescription)")
            throw SharingError.participantNotFound
        }

        let isAlreadyOnShare = share.participants.contains { existing in
            if let existingRecordID = existing.userIdentity.userRecordID,
               let newRecordID = participant.userIdentity.userRecordID {
                return existingRecordID == newRecordID
            }
            return existing.userIdentity.lookupInfo?.emailAddress == participant.userIdentity.lookupInfo?.emailAddress
        }
        guard !isAlreadyOnShare else { throw SharingError.alreadyParticipant }

        participant.permission = permission
        share.addParticipant(participant)

        let (saveResults, _) = try await database.modifyRecords(saving: [share], deleting: [])
        guard case .success(let savedRecord) = saveResults[share.recordID], let savedShare = savedRecord as? CKShare else {
            throw SharingError.shareSaveFailed
        }
        SharingPermissionStore.shared.update(forLibraryId: libraryId, share: savedShare)
    }

    /// `nil` when the library isn't currently shared — not an error, since most libraries never
    /// are.
    func fetchShare(forLibraryId libraryId: UUID) async throws -> CKShare? {
        let rootRecordID = CKRecord.ID.record(syncId: libraryId, zoneID: .library(libraryId))
        let rootRecord: CKRecord
        do {
            rootRecord = try await database.record(for: rootRecordID)
        } catch {
            throw SharingError.notYetSynced
        }

        guard let shareReference = rootRecord.share else {
            SharingPermissionStore.shared.update(forLibraryId: libraryId, share: nil)
            return nil
        }

        let shareRecord = try await database.record(for: shareReference.recordID)
        let share = shareRecord as? CKShare
        SharingPermissionStore.shared.update(forLibraryId: libraryId, share: share)

        // Under `-EnableLiveSync` only, surface the share's invite URL to OSLog so the
        // NoteBytez20260823v1-UITests.md Phase 4 manual two-account procedure can pick it up
        // (`xcrun simctl spawn <udid> log stream …`) and open it on the second device without
        // needing `UICloudSharingController`'s Copy Link. Never logged in a normal build.
        if ProcessInfo.processInfo.arguments.contains("-EnableLiveSync"), let shareURL = share?.url {
            logger.notice("[EnableLiveSync] Share URL for library \(libraryId, privacy: .public): \(shareURL.absoluteString, privacy: .public)")
        }
        return share
    }

    func updatePermission(_ permission: CKShare.ParticipantPermission, for participant: CKShare.Participant, in share: CKShare, libraryId: UUID) async throws {
        participant.permission = permission
        do {
            let (saveResults, _) = try await database.modifyRecords(saving: [share], deleting: [])
            guard case .success(let savedRecord) = saveResults[share.recordID], let savedShare = savedRecord as? CKShare else {
                throw SharingError.permissionUpdateFailed
            }
            SharingPermissionStore.shared.update(forLibraryId: libraryId, share: savedShare)
        } catch {
            logger.error("Failed to update participant permission: \(error.localizedDescription)")
            throw SharingError.permissionUpdateFailed
        }
    }

    func removeParticipant(_ participant: CKShare.Participant, from share: CKShare, libraryId: UUID) async throws {
        share.removeParticipant(participant)
        let (saveResults, _) = try await database.modifyRecords(saving: [share], deleting: [])
        guard case .success(let savedRecord) = saveResults[share.recordID], let savedShare = savedRecord as? CKShare else {
            throw SharingError.permissionUpdateFailed
        }
        SharingPermissionStore.shared.update(forLibraryId: libraryId, share: savedShare)
    }

    /// The owner ending the share entirely — every participant loses access. Deleting the
    /// `CKShare` record (not the root Library record, which stays exactly as it was).
    func stopSharing(_ share: CKShare, libraryId: UUID) async throws {
        _ = try await database.modifyRecords(saving: [], deleting: [share.recordID])
        SharingPermissionStore.shared.update(forLibraryId: libraryId, share: nil)
    }

}
