// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictStore.swift
//  NoteBytez
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

/// A conflict the user just resolved by hand — shown in place in S9 as a "Resolved ✓" row for a
/// short beat before it animates out (`Docs/Bugs/20260910v1-Sync.md` SF 4).
struct ResolvedConflictAck: Identifiable {
    let id = UUID()
    let syncId: UUID
    /// The "kept …" phrasing from `Conflict.resolutionSummary(for:)`.
    let summary: String
}

/// A manual resolution still inside its ~5-second undo window (`Docs/Bugs/20260910v1-Sync.md`
/// SF 7). Carries enough to put the conflict back in the queue and, with a live engine, to
/// re-apply the pre-resolution record.
struct ConflictResolutionUndo: Identifiable {
    let id = UUID()
    let conflict: Conflict
    let choice: ConflictResolutionChoice
    let resolvedOn: Date
}

/// Unresolved conflicts queued for S10 (Keep All Versions / Diff-Merge strategies), plus any
/// pending Last-Write-Wins auto-resolutions still open to revert, plus the transient
/// acknowledgement / undo state for a just-resolved conflict. `SyncEngine` is the sole writer;
/// S9/S10/S4's `ConflictBanner` are readers.
@Observable
final class ConflictStore {

    static let shared = ConflictStore()

    /// How long a resolved conflict's "Resolved ✓" row lingers before it leaves S9, and how
    /// long the user then has to undo the resolution. Injected (with production defaults) only
    /// so tests can shrink the waits without touching global state.
    let acknowledgementDuration: Duration
    let undoWindow: Duration

    private(set) var conflicts: [Conflict] = []
    private(set) var autoResolutions: [UUID: ConflictAutoResolution] = [:]
    private(set) var recentlyResolved: [UUID: ResolvedConflictAck] = [:]
    private(set) var pendingUndo: ConflictResolutionUndo?

    /// One timer per acknowledged conflict (keyed by `syncId`), plus one for the current undo
    /// window — held so a rapid re-resolution or an explicit clear can cancel the pending
    /// expiry rather than letting a stale `Task` fire later.
    private var acknowledgementTasks: [UUID: Task<Void, Never>] = [:]
    private var undoTask: Task<Void, Never>?

    init(acknowledgementDuration: Duration = .seconds(1.5), undoWindow: Duration = .seconds(5)) {
        self.acknowledgementDuration = acknowledgementDuration
        self.undoWindow = undoWindow
    }

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

    // MARK: - Manual-resolution acknowledgement + undo

    /// Records the in-place "Resolved ✓" acknowledgement and opens the undo window for a manual
    /// resolution. Called by `SyncEngine.resolveConflictManually` only after the resolution has
    /// actually been persisted.
    func recordResolution(of conflict: Conflict, choice: ConflictResolutionChoice) {
        let syncId = conflict.syncId
        recentlyResolved[syncId] = ResolvedConflictAck(syncId: syncId, summary: conflict.resolutionSummary(for: choice))
        acknowledgementTasks[syncId]?.cancel()
        acknowledgementTasks[syncId] = Task { [weak self, acknowledgementDuration] in
            try? await Task.sleep(for: acknowledgementDuration)
            guard !Task.isCancelled else { return }
            self?.clearAcknowledgement(syncId: syncId)
        }

        pendingUndo = ConflictResolutionUndo(conflict: conflict, choice: choice, resolvedOn: Date())
        undoTask?.cancel()
        undoTask = Task { [weak self, undoWindow] in
            try? await Task.sleep(for: undoWindow)
            guard !Task.isCancelled else { return }
            self?.clearUndo()
        }
    }

    func clearAcknowledgement(syncId: UUID) {
        acknowledgementTasks[syncId]?.cancel()
        acknowledgementTasks[syncId] = nil
        recentlyResolved[syncId] = nil
    }

    func clearUndo() {
        undoTask?.cancel()
        undoTask = nil
        pendingUndo = nil
    }

}
