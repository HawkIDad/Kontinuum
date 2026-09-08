// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SharingViewModel.swift
//  NoteBytez
//

import CloudKit
import Foundation
import Observation

/// Drives S22 (Sharing / Participants) — fetches the current `CKShare` for a library (if any),
/// creates one on first invite, and manages participant permissions. All CloudKit calls go
/// through `SharingService`; this layer is what the view binds to and what turns its errors into
/// display state, the same split `SavedViewViewModel`/`TaskDashboardViewModel` already establish
/// between "talks to the data layer" and "drives the screen."
@Observable
final class SharingViewModel {

    let libraryId: UUID
    let libraryName: String

    private(set) var share: CKShare?
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    /// Set once `SharingService.createShare`/`fetchShare` returns — this is what the view passes
    /// to the native invite controller (`CloudSharingControllerRepresentable`).
    var isPresentingInviteController = false

    private let service: SharingService

    init(libraryId: UUID, libraryName: String, service: SharingService = .shared) {
        self.libraryId = libraryId
        self.libraryName = libraryName
        self.service = service
    }

    var participants: [CKShare.Participant] {
        (share?.participants ?? []).filter { $0.role != .owner }
    }

    /// The owner can manage permissions/remove participants/stop sharing; a participant viewing
    /// their own shared-to-them copy can only see who else is on it — per S22's "explicit invite
    /// action" being owner-only, and per the Release Features' own read/read-write distinction
    /// only ever making sense for the owner to set.
    var isOwner: Bool {
        share?.currentUserParticipant?.role == .owner
    }

    func loadShare() async {
        isLoading = true
        defer { isLoading = false }
        do {
            share = try await service.fetchShare(forLibraryId: libraryId)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Creates the share if one doesn't exist yet, then opens the native invite controller.
    func startInviting() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if share == nil {
                share = try await service.createShare(forLibraryId: libraryId, libraryName: libraryName)
            }
            errorMessage = nil
            isPresentingInviteController = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Adds a participant to the library's share by Apple Account email — no
    /// `UICloudSharingController`, no Mail/Messages. Creates the share on first use (via
    /// `SharingService.addParticipant`), then reloads so the new participant shows in the list.
    /// See Docs/Plans/NoteBytez20260831v1-Sharing.md.
    func addParticipant(email: String, permission: CKShare.ParticipantPermission) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await service.addParticipant(emailAddress: email, permission: permission, forLibraryId: libraryId, libraryName: libraryName)
            errorMessage = nil
            await loadShare()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updatePermission(_ permission: CKShare.ParticipantPermission, for participant: CKShare.Participant) async {
        guard let share else { return }
        do {
            try await service.updatePermission(permission, for: participant, in: share, libraryId: libraryId)
            await loadShare()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeParticipant(_ participant: CKShare.Participant) async {
        guard let share else { return }
        do {
            try await service.removeParticipant(participant, from: share, libraryId: libraryId)
            await loadShare()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stopSharing() async {
        guard let share else { return }
        do {
            try await service.stopSharing(share, libraryId: libraryId)
            self.share = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissError() {
        errorMessage = nil
    }

}
