// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CurrentUserStore.swift
//  Kontinuum
//

import CloudKit
import Foundation
import OSLog

/// The current iCloud user's display identifier — what Phase 10 populates `createdBy`/
/// `updatedBy` with, now that CloudKit Sharing gives those MVP-reserved audit fields (see
/// `ARCHITECTURE.md`'s Soft Delete section) a real multi-user meaning.
///
/// Resolution (`resolveCurrentUser()`) is async (`CKContainer.userRecordID()` is a network
/// call), but every DAL write is synchronous — so this caches the last-resolved identifier
/// (in-memory, backed by `UserDefaults` so it survives relaunch before the next resolution
/// completes) and exposes it as a plain synchronous property, the same
/// resolve-async/read-sync split `ConflictStrategyStore.currentStrategy()` already established.
final class CurrentUserStore: @unchecked Sendable {

    static let shared = CurrentUserStore()

    private static let defaultsKey = "CurrentUserStore.identifier"

    private let defaults: UserDefaults
    private let lock = NSLock()
    private var _currentUserIdentifier: String?

    /// The current user's `CKRecord.ID.recordName` — opaque but stable and always available.
    /// `nil` only when no resolution has ever completed (single-user, pre-Phase-10 behavior, or
    /// CloudKit unavailable).
    var currentUserIdentifier: String? {
        lock.withLock { _currentUserIdentifier }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self._currentUserIdentifier = defaults.string(forKey: Self.defaultsKey)
    }

    /// Called once at `SyncEngine.start` (Release builds only, same as the rest of the sync
    /// stack) and again on `.accountChange` — never in unit tests, which never touch
    /// `CKContainer`.
    ///
    /// Deliberately doesn't attempt to resolve a human-readable name via
    /// `CKContainer.userIdentity(forUserRecordID:)` — that discovery API is deprecated in favor
    /// of reading identity off a `CKShare.Participant` you already have (see
    /// `SharingPermissionStore`, which does exactly that for *other* participants). The current
    /// user's own `CKRecord.ID.recordName` is already a stable, unique-enough identifier for
    /// `createdBy`/`updatedBy` attribution — a real name is a display nicety, not something
    /// audit fields need.
    func resolveCurrentUser(containerIdentifier: String) async {
        let container = CKContainer(identifier: containerIdentifier)
        do {
            let recordID = try await container.userRecordID()
            self.set(recordID.recordName)
        } catch {
            Log.logger(.sync).error("Failed to resolve current iCloud user: \(error.localizedDescription)")
        }
    }

    /// Test/preview seam — production code always goes through `resolveCurrentUser`.
    func set(_ identifier: String?) {
        lock.withLock { _currentUserIdentifier = identifier }
        defaults.set(identifier, forKey: Self.defaultsKey)
    }

}
