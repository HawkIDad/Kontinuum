// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictStore.swift
//  Kontinuum
//

import Foundation
import Observation

/// A Strategy-2 (Last-Write-Wins) auto-resolution the user hasn't dismissed yet — what
/// `ConflictBanner` reads to show "kept the newer edit" plus a Revert action, per-document.
struct ConflictAutoResolution: Identifiable {
    let id = UUID()
    let conflict: Conflict
    let kept: ConflictResolutionChoice
    let keptLabel: String
}

/// Unresolved conflicts queued for S10 (Keep All Versions / Diff-Merge strategies), plus any
/// pending Last-Write-Wins auto-resolutions still open to revert. `SyncEngine` is the sole
/// writer; S9/S10/S4's `ConflictBanner` are readers.
@Observable
final class ConflictStore {

    static let shared = ConflictStore()

    private(set) var conflicts: [Conflict] = []
    private(set) var autoResolutions: [UUID: ConflictAutoResolution] = [:]

    init() {}

    /// Replaces any existing queued conflict for the same record — if the user edited again
    /// before resolving, the newer capture is what S10 should show.
    func queue(_ conflict: Conflict) {
        conflicts.removeAll { $0.syncId == conflict.syncId }
        conflicts.append(conflict)
    }

    func remove(_ conflict: Conflict) {
        conflicts.removeAll { $0.id == conflict.id }
    }

    func conflict(syncId: UUID) -> Conflict? {
        conflicts.first { $0.syncId == syncId }
    }

    func recordAutoResolution(_ resolution: ConflictAutoResolution) {
        autoResolutions[resolution.conflict.syncId] = resolution
    }

    func autoResolution(syncId: UUID) -> ConflictAutoResolution? {
        autoResolutions[syncId]
    }

    func clearAutoResolution(syncId: UUID) {
        autoResolutions[syncId] = nil
    }

}
