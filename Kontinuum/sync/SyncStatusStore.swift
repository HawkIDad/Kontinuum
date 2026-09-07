// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncStatusStore.swift
//  Kontinuum
//

import Foundation
import Network
import Observation

/// One log entry in S9's chronological event list — timestamp + description, flagged for the
/// orange error/conflict styling `SyncLogRow` uses.
struct SyncLogEntry: Identifiable {

    let id = UUID()
    let timestamp: Date
    let message: String
    let isError: Bool

}

nonisolated enum SyncStatus: Equatable {
    case offline
    case syncing
    case conflict
    case synced
}

/// The single source of truth S9 (and the persistent `SyncStatusGlyph` on S3/S4) read from.
/// `SyncEngine` is the only writer — it translates `CKSyncEngine.Event`s into calls here so the
/// UI layer never touches CloudKit types directly.
///
/// `status` is derived from three independent flags rather than stored directly, so each
/// trigger (network reachability, an in-flight sync, an unresolved conflict) can change
/// independently without the call sites needing to know the full state-transition table —
/// see the doc comment on `status` for the priority order.
///
/// MainActor-isolated implicitly, like the rest of the module (`SWIFT_DEFAULT_ACTOR_ISOLATION`).
@Observable
final class SyncStatusStore {

    static let shared = SyncStatusStore()

    private static let maxLogEntries = 50

    private(set) var isSyncing = false
    private(set) var isOffline = false
    private(set) var conflictCount = 0
    private(set) var lastSyncedOn: Date?
    private(set) var logEntries: [SyncLogEntry] = []
    private(set) var dismissibleError: SyncLogEntry?

    private var pathMonitor: NWPathMonitor?

    init() {}

    /// Offline gray-dot beats an in-flight spinner beats an unresolved conflict beats plain
    /// green "Synced" — matches `UIUX/06-DesignSystem.md`'s sync visual-language table.
    var status: SyncStatus {
        if isOffline { return .offline }
        if isSyncing { return .syncing }
        if conflictCount > 0 { return .conflict }
        return .synced
    }

    /// Starts `NWPathMonitor` — deferred out of `init()` (unlike every other stored property
    /// here) so a plain `SyncStatusStore()` built in a unit test never touches real networking
    /// and stays deterministic. Called once from `SyncEngine.start`, Release builds only, same
    /// as the rest of the sync stack.
    func startMonitoringNetwork() {
        guard pathMonitor == nil else { return }
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            let isOffline = path.status != .satisfied
            Task { @MainActor in SyncStatusStore.shared.isOffline = isOffline }
        }
        monitor.start(queue: DispatchQueue(label: "com.g9Consulting.Kontinuum.SyncStatusStore"))
        pathMonitor = monitor
    }

    func syncWillStart() {
        isSyncing = true
    }

    func syncDidFinish() {
        isSyncing = false
        lastSyncedOn = Date()
    }

    func recordSyncedNotes(count: Int, received: Bool) {
        guard count > 0 else { return }
        let noun = count == 1 ? "note" : "notes"
        let verb = received ? "received" : "updated"
        appendEntry(message: "Synced — \(count) \(noun) \(verb)", isError: false)
    }

    func recordConflict(noteTitle: String?) {
        conflictCount += 1
        appendEntry(message: "Conflict — \"\(noteTitle ?? "a note")\"", isError: true)
    }

    /// A conflict a strategy resolved automatically (Last-Write-Wins, or Diff-Merge falling
    /// back to it for non-text records) — logged, but doesn't touch `conflictCount`, which
    /// tracks conflicts still waiting on the user.
    func recordResolvedConflict(noteTitle: String) {
        appendEntry(message: "Auto-resolved — \"\(noteTitle)\"", isError: false)
    }

    func recordError(_ message: String) {
        let entry = SyncLogEntry(timestamp: Date(), message: message, isError: true)
        logEntries.insert(entry, at: 0)
        dismissibleError = entry
        trimLog()
    }

    func dismissError() {
        dismissibleError = nil
    }

    /// Called once a single queued conflict is actually resolved (S10, or an automatic
    /// strategy) — decrements rather than zeroing outright, since other conflicts may still be
    /// unresolved.
    func decrementConflictCount() {
        conflictCount = max(0, conflictCount - 1)
    }

    private func appendEntry(message: String, isError: Bool) {
        logEntries.insert(SyncLogEntry(timestamp: Date(), message: message, isError: isError), at: 0)
        trimLog()
    }

    private func trimLog() {
        if logEntries.count > Self.maxLogEntries {
            logEntries.removeLast(logEntries.count - Self.maxLogEntries)
        }
    }

}
