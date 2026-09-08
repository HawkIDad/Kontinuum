// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncStateStore.swift
//  NoteBytez
//

import CloudKit
import Foundation

/// Persists `CKSyncEngine`'s own serialized state (pending changes, change tokens) across app
/// relaunch, so the engine resumes exactly where it left off instead of re-fetching everything.
///
/// One `CKSyncEngine` per database as of Phase 10 (the owner's private database, always; a
/// second one against the shared database once a `CKShare` is accepted — see `SyncEngine`) —
/// `scope` keys the two independently so accepting a share can never clobber the private
/// engine's already-persisted state, and vice versa.
enum SyncStateStoreScope: String {
    case owned = "Owned"
    case shared = "Shared"
}

/// Phase 11 (Security-Local Files): file-based rather than `UserDefaults`-backed (MVP Phase 12's
/// original choice), specifically so `.completeFileProtection` can be applied — `UserDefaults`
/// has no public API for setting a per-key file-protection level on its backing plist.
/// **Deliberate, stated one-time cost**: an existing install's `UserDefaults`-persisted state
/// isn't migrated forward — `CKSyncEngine` simply starts from `nil` state (a full resync) the
/// first time this ships, exactly the same recovery path it already takes on a fresh install.
/// No data loss: CloudKit remains the source of truth for what's been synced, this file only
/// caches change tokens as an optimization.
enum SyncStateStore {

    static func stateDirectory(in fileManager: FileManager = .default) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("SyncState", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func fileURL(for scope: SyncStateStoreScope, in directory: URL) -> URL {
        directory.appendingPathComponent("state\(scope.rawValue).json")
    }

    static func load(scope: SyncStateStoreScope = .owned, in directory: URL = stateDirectory()) -> CKSyncEngine.State.Serialization? {
        guard let data = try? Data(contentsOf: fileURL(for: scope, in: directory)) else { return nil }
        return try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data)
    }

    static func save(_ serialization: CKSyncEngine.State.Serialization, scope: SyncStateStoreScope = .owned, in directory: URL = stateDirectory()) {
        guard let data = try? JSONEncoder().encode(serialization) else { return }
        writeProtected(data, to: fileURL(for: scope, in: directory))
    }

    /// Split out from `save` so the `.completeFileProtection` write itself is unit-testable with
    /// arbitrary `Data` — `CKSyncEngineStateSerialization` (`CKSyncEngine.State.Serialization`'s
    /// underlying type) has no public initializer, only ever produced by a live, already-
    /// connected `CKSyncEngine`, so a real one can't be fabricated in a test. The write mechanics
    /// don't depend on the payload, so exercising this directly covers the identical code path
    /// `save` uses in production.
    static func writeProtected(_ data: Data, to url: URL) {
        try? data.write(to: url, options: .completeFileProtection)
    }

}
