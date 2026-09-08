// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncStatusViewModel.swift
//  NoteBytez
//

import Foundation
import Observation

/// Drives both the persistent `SyncStatusGlyph` (S3/S4 toolbars) and S9 (Sync Status / Log) —
/// a thin display/formatting layer over `SyncStatusStore`, which `SyncEngine` is the sole
/// writer of.
@Observable
final class SyncStatusViewModel {

    private let store: SyncStatusStore
    private let libraryId: UUID?
    private let sharingPermissionStore: SharingPermissionStore

    init(libraryId: UUID? = nil, store: SyncStatusStore = .shared, sharingPermissionStore: SharingPermissionStore = .shared) {
        self.libraryId = libraryId
        self.store = store
        self.sharingPermissionStore = sharingPermissionStore
    }

    var status: SyncStatus { store.status }

    /// Phase 10's "shared-space indicator" — extends the existing glyph/log rather than adding a
    /// parallel display, per this phase's own plan wording. True either as the owner (this
    /// device has actively fetched/created a `CKShare` for the library — `SharingPermissionStore`)
    /// or as a participant (this device accepted someone else's share — `SharedLibraryRegistry`).
    var isSharedLibrary: Bool {
        guard let libraryId else { return false }
        return sharingPermissionStore.isShared(libraryId) || SharedLibraryRegistry.shared.isShared(libraryId)
    }
    var logEntries: [SyncLogEntry] { store.logEntries }
    var dismissibleError: SyncLogEntry? { store.dismissibleError }

    /// "Offline: gray dot, 'Last synced Xm ago' label persists" — `UIUX/06-DesignSystem.md`'s
    /// sync visual language explicitly wants this timestamp visible in every state, not just
    /// when synced.
    var lastSyncedText: String {
        guard let lastSyncedOn = store.lastSyncedOn else { return "Never synced" }
        return "Last synced: \(lastSyncedOn.formatted(.relative(presentation: .named)))"
    }

    var statusHeadline: String {
        switch status {
        case .synced: return "Synced"
        case .syncing: return "Syncing…"
        case .offline: return "Offline"
        case .conflict:
            let count = store.conflictCount
            return count == 1 ? "Conflict on 1 note" : "Conflict on \(count) notes"
        }
    }

    var statusSystemImage: String {
        status == .conflict ? "exclamationmark.triangle" : "arrow.triangle.2.circlepath"
    }

    /// `.synced` is the only state that reads as "success" green — every other state (including
    /// the mid-flight `.syncing` spinner) stays neutral/warning per the design system.
    var statusTint: StatusTint {
        switch status {
        case .synced: return .success
        case .conflict: return .warning
        case .syncing, .offline: return .neutral
        }
    }

    enum StatusTint {
        case success, warning, neutral
    }

    func syncNow() {
        Task { await SyncEngine.shared.syncNow() }
    }

    func dismissError() {
        store.dismissError()
    }

}
