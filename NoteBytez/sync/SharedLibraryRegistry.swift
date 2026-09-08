// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SharedLibraryRegistry.swift
//  NoteBytez
//

import CloudKit
import Foundation

/// Which libraries live in this device's *shared* CKDatabase (a library someone else owns and
/// shared to this device) versus its *private* one (every library this device owns, shared or
/// not) — plus, for a shared one, the real zone `ownerName` CloudKit assigned it.
///
/// Two things this unlocks, both otherwise impossible: `SyncEngine.recordChanged` needs to know
/// which of its two `CKSyncEngine` instances (private vs. shared database) owns a given pending
/// change; and `CKRecordZone.ID.library(_:ownerName:)` needs the *real* owner name for a shared
/// zone — `CKCurrentUserDefaultName` (this codebase's existing default) only resolves correctly
/// for a zone this device itself owns. Captured once, at `SyncEngine.acceptShare`, from the
/// accepted `CKShare.Metadata`.
///
/// Local-only, like `SyncStateStore`/`ConflictStore` — never synced, never a SwiftData model
/// (per `ARCHITECTURE.md`'s "Local-only data" convention).
final class SharedLibraryRegistry: @unchecked Sendable {

    static let shared = SharedLibraryRegistry()

    private static let defaultsKey = "SharedLibraryRegistry.ownerNamesByLibraryId"

    private let defaults: UserDefaults
    private let lock = NSLock()
    private var ownerNamesByLibraryId: [UUID: String]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let stored = defaults.dictionary(forKey: Self.defaultsKey) as? [String: String] ?? [:]
        self.ownerNamesByLibraryId = stored.reduce(into: [:]) { result, entry in
            guard let libraryId = UUID(uuidString: entry.key) else { return }
            result[libraryId] = entry.value
        }
    }

    func isShared(_ libraryId: UUID) -> Bool {
        lock.withLock { ownerNamesByLibraryId[libraryId] != nil }
    }

    /// The zone's real owner (a specific iCloud user, not this device's own account) — `nil`
    /// for any library this device owns, which is the common case.
    func ownerName(forLibraryId libraryId: UUID) -> String? {
        lock.withLock { ownerNamesByLibraryId[libraryId] }
    }

    func markShared(_ libraryId: UUID, ownerName: String) {
        lock.withLock { ownerNamesByLibraryId[libraryId] = ownerName }
        persist()
    }

    func unmarkShared(_ libraryId: UUID) {
        lock.withLock { ownerNamesByLibraryId[libraryId] = nil }
        persist()
    }

    private func persist() {
        let stored = lock.withLock { ownerNamesByLibraryId }
        let asStrings = stored.reduce(into: [String: String]()) { result, entry in
            result[entry.key.uuidString] = entry.value
        }
        defaults.set(asStrings, forKey: Self.defaultsKey)
    }

}
