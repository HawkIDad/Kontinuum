// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictResolutionViewModel.swift
//  Kontinuum
//

import CloudKit
import Foundation
import SwiftData
import Observation

/// Drives S10 for a single `Conflict` — reached by tapping a queued conflict (S9's log, or a
/// dedicated "Resolve" affordance there). Which of the three strategy-specific UIs S10 shows
/// is driven by `strategy`, read fresh from `ConflictStrategyStore` rather than passed in, so a
/// mid-session setting change is reflected immediately.
@Observable
final class ConflictResolutionViewModel {

    let conflict: Conflict
    private let modelContext: ModelContext

    private(set) var isResolving = false

    /// Only populated when `conflict.hasDiffableContent` — empty otherwise, so
    /// `ConflictResolutionView` falls back to the Keep-All-Versions UI for non-`Document`
    /// conflicts even if Diff-Merge is the active strategy.
    private(set) var diffHunks: [DiffHunk] = []
    var acceptedHunkIDs: Set<UUID> = []

    var strategy: ConflictStrategy { ConflictStrategyStore.currentStrategy() }

    init(conflict: Conflict, modelContext: ModelContext) {
        self.conflict = conflict
        self.modelContext = modelContext

        guard conflict.hasDiffableContent else { return }
        let hunks = MarkdownDiffMerge.hunks(
            old: conflict.serverRecord["content"] as? String ?? "",
            new: conflict.clientRecord["content"] as? String ?? ""
        )
        diffHunks = hunks
        // Every changed hunk defaults to keeping this device's edit — the user flips
        // individual hunks back to the server's line rather than starting from nothing.
        acceptedHunkIDs = Set(hunks.filter { $0.kind == .changed }.map(\.id))
    }

    var mergedPreview: String {
        MarkdownDiffMerge.merge(hunks: diffHunks, acceptedHunkIDs: acceptedHunkIDs)
    }

    func toggleHunk(_ hunk: DiffHunk) {
        if acceptedHunkIDs.contains(hunk.id) {
            acceptedHunkIDs.remove(hunk.id)
        } else {
            acceptedHunkIDs.insert(hunk.id)
        }
    }

    /// Strategy 1 — the user picks a side (or both) explicitly.
    func resolve(choice: ConflictResolutionChoice) async {
        isResolving = true
        await SyncEngine.shared.resolveConflict(conflict, choice: choice, in: modelContext)
        SyncStatusStore.shared.decrementConflictCount()
        isResolving = false
    }

    /// Strategy 3 — the user's accepted/rejected hunks, applied as the final merged content.
    func confirmMerge() async {
        await resolve(choice: .merged(content: mergedPreview))
    }

}
