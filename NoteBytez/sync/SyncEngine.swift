// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncEngine.swift
//  Kontinuum
//

import CloudKit
import Foundation
import OSLog
import SwiftData

/// Manual `CKSyncEngine` wiring against the private database: one `CKRecordZone` per Library,
/// every other record parented to that zone's root Library record via a `library` reference
/// field, record IDs reusing each model's `{model}Id` UUID as `CKRecord.ID.recordName`.
///
/// Replaces Phase 0's placeholder `ModelConfiguration(cloudKitDatabase:)` wiring — SwiftData's
/// automatic CloudKit sync never surfaces individual record events or both sides of a conflict
/// to app code, which Phase 13 (sync log) and Phase 14 (conflict strategies) both need.
///
/// All CloudKit object construction is deferred to `start(modelContainer:)` rather than
/// `init()`, so merely referencing `SyncEngine.shared` (e.g. from a DAL call in a unit test,
/// where `start` is never invoked) never touches `CKContainer`/entitlements and stays a no-op.
final class SyncEngine: @unchecked Sendable {

    static let shared = SyncEngine()

    static let subscriptionID: CKSubscription.ID = "kontinuum-private-changes"
    /// A second, distinct subscription for the shared database (Phase 10) — the private and
    /// shared databases are separate CloudKit endpoints, each needing its own subscription and
    /// its own `CKSyncEngine` instance (see `sharedEngine` below).
    static let sharedSubscriptionID: CKSubscription.ID = "kontinuum-shared-changes"
    /// `internal`, not `private` — `SharingService` needs the same container identifier for its
    /// own direct `CKShare` CRUD, and duplicating the literal string would risk the two ever
    /// drifting (same rationale as this codebase's other `private` → `internal` widenings, e.g.
    /// `ExportDAL.sanitizedFilename`).
    static let containerIdentifier = "iCloud.com.g9Consulting.Kontinuum"

    private let logger = Log.logger(.sync)

    private var modelContainer: ModelContainer?
    private var database: CKDatabase?
    private var engine: CKSyncEngine?

    /// The shared database's own engine — created alongside `engine` in `start()`, but only
    /// ever has anything to fetch once `acceptShare` accepts an incoming `CKShare`. Kept
    /// separate rather than reused because `CKSyncEngine` is bound to one `CKDatabase` for its
    /// lifetime (the private and shared databases are genuinely different CloudKit endpoints).
    private var sharedDatabase: CKDatabase?
    private var sharedEngine: CKSyncEngine?

    /// Entitlement suspension (NoteBytez20260907v1-Security.md Phase 5). While the app is in its
    /// blocked state, no local change is pushed and no fetched change is applied — fetched
    /// batches are buffered and replayed on `resume()` so nothing is lost and nothing is
    /// destructively deleted from a user who has simply lapsed. Guarded by its own lock; the
    /// rest of `SyncEngine`'s mutable state is serialized by `CKSyncEngine`'s own delegate
    /// dispatch, but `suspend()`/`resume()` are called from the entitlement gate on `MainActor`.
    private let suspensionLock = NSLock()
    private var isEntitlementSuspended = false
    private var bufferedFetchedChanges: [CKSyncEngine.Event.FetchedRecordZoneChanges] = []

    private var isSuspendedSnapshot: Bool {
        suspensionLock.withLock { isEntitlementSuspended }
    }

    private init() {}

    /// Called once at app launch (Release builds only — see `KontinuumApp`) with the shared
    /// `ModelContainer`. Ensures every already-active library has a zone, so a library created
    /// before the engine started (or restored from a fresh install) still gets synced.
    func start(modelContainer: ModelContainer) {
        guard engine == nil else { return }
        self.modelContainer = modelContainer

        let ckContainer = CKContainer(identifier: Self.containerIdentifier)

        let database = ckContainer.privateCloudDatabase
        self.database = database
        var configuration = CKSyncEngine.Configuration(
            database: database,
            stateSerialization: SyncStateStore.load(scope: .owned),
            delegate: self
        )
        configuration.subscriptionID = Self.subscriptionID
        self.engine = CKSyncEngine(configuration)

        let sharedDatabase = ckContainer.sharedCloudDatabase
        self.sharedDatabase = sharedDatabase
        var sharedConfiguration = CKSyncEngine.Configuration(
            database: sharedDatabase,
            stateSerialization: SyncStateStore.load(scope: .shared),
            delegate: self
        )
        sharedConfiguration.subscriptionID = Self.sharedSubscriptionID
        self.sharedEngine = CKSyncEngine(sharedConfiguration)

        SyncStatusStore.shared.startMonitoringNetwork()
        ensureZonesForActiveLibraries()

        Task {
            await CurrentUserStore.shared.resolveCurrentUser(containerIdentifier: Self.containerIdentifier)
        }
    }

    /// Called on receipt of a silent push for either subscription — see `AppDelegate`. A push
    /// doesn't say which database changed, so this just checks both; a `fetchChanges()` with
    /// nothing new is cheap.
    func handleRemoteNotification() async {
        guard !isSuspendedSnapshot else { return }
        do {
            try await engine?.fetchChanges()
        } catch {
            logger.error("fetchChanges (private) from push failed: \(error.localizedDescription)")
        }
        do {
            try await sharedEngine?.fetchChanges()
        } catch {
            logger.error("fetchChanges (shared) from push failed: \(error.localizedDescription)")
        }
    }

    /// S9's manual "Sync Now" trigger — otherwise `CKSyncEngine` schedules sync passes on its
    /// own (`configuration.automaticallySync`), the same event stream either way.
    func syncNow() async {
        guard !isSuspendedSnapshot else { return }
        if let engine {
            do {
                try await engine.sendChanges()
                try await engine.fetchChanges()
            } catch {
                logger.error("Manual sync (private) failed: \(error.localizedDescription)")
                SyncStatusStore.shared.recordError(error.localizedDescription)
            }
        }
        if let sharedEngine {
            do {
                try await sharedEngine.sendChanges()
                try await sharedEngine.fetchChanges()
            } catch {
                logger.error("Manual sync (shared) failed: \(error.localizedDescription)")
                SyncStatusStore.shared.recordError(error.localizedDescription)
            }
        }
    }

    /// Accepts an incoming `CKShare` (Phase 10) — the far side of `SharingService.createShare`,
    /// triggered by `AppDelegate`'s `userDidAcceptCloudKitShareWith` handlers. Registers the
    /// shared library in `SharedLibraryRegistry` (so every zone-ID computation elsewhere in
    /// `sync/` routes correctly from here on), upserts the Library root record CloudKit already
    /// handed us in `metadata.rootRecord` (no extra fetch needed), then asks `sharedEngine` to
    /// pull the rest of that zone's content.
    func acceptShare(_ metadata: CKShare.Metadata) async {
        let container = CKContainer(identifier: Self.containerIdentifier)
        do {
            let acceptedShare = try await container.accept(metadata)

            guard let rootRecord = metadata.rootRecord,
                  let libraryId = UUID(uuidString: rootRecord.recordID.recordName) else {
                logger.error("Accepted share has no resolvable Library root record")
                return
            }

            SharedLibraryRegistry.shared.markShared(libraryId, ownerName: rootRecord.recordID.zoneID.ownerName)
            SharingPermissionStore.shared.update(forLibraryId: libraryId, share: acceptedShare)

            if let modelContainer {
                let context = ModelContext(modelContainer)
                SyncRecordFactory.applyIncoming(rootRecord, in: context)
                try? context.save()
            }

            try await sharedEngine?.fetchChanges()
        } catch {
            logger.error("Failed to accept share: \(error.localizedDescription)")
            SyncStatusStore.shared.recordError("Couldn't accept the shared library: \(error.localizedDescription)")
        }
    }

    /// Applies `choice` for `conflict`: saves the resolved record directly against the
    /// database (bypassing the normal pending-change batch — its stale entry for this record
    /// is cleared here instead, since we're handling it out of band), then applies the result
    /// to local SwiftData. `.keepBoth` additionally duplicates the client's content into a new
    /// `Document` — the one model type worth literally duplicating.
    func resolveConflict(_ conflict: Conflict, choice: ConflictResolutionChoice, in context: ModelContext) async {
        let isShared = SharedLibraryRegistry.shared.isShared(conflict.libraryId)
        guard let targetEngine = isShared ? sharedEngine : engine,
              let targetDatabase = isShared ? sharedDatabase : database else { return }
        targetEngine.state.remove(pendingRecordZoneChanges: [.saveRecord(conflict.serverRecord.recordID)])

        do {
            let saved = try await targetDatabase.save(ConflictResolver.resolvedRecord(for: conflict, choice: choice))
            SyncRecordFactory.applyIncoming(saved, in: context)

            if choice == .keepBoth, conflict.recordType == Document.ckRecordType {
                duplicateAsNewDocument(from: conflict, in: context)
            }

            try? context.save()
            ConflictStore.shared.remove(conflict)
            ConflictStore.shared.clearAutoResolution(syncId: conflict.syncId)
        } catch {
            logger.error("Failed to resolve conflict for \(conflict.recordType) \(conflict.syncId): \(error.localizedDescription)")
            SyncStatusStore.shared.recordError("Couldn't resolve conflict on \"\(conflict.title)\": \(error.localizedDescription)")
        }
    }

    private func duplicateAsNewDocument(from conflict: Conflict, in context: ModelContext) {
        guard let title = conflict.clientRecord["title"] as? String, let content = conflict.clientRecord["content"] as? String else { return }
        _ = DocumentDAL.create(title: "\(title) (Conflict Copy)", content: content, libraryId: conflict.libraryId, in: context)
    }

    /// Ensures a zone exists for `libraryId` and enqueues its root Library record for upload —
    /// called by `LibraryDAL.create` for a brand-new library, and once at launch for every
    /// already-active one. A no-op for a library shared *to* this device — that zone already
    /// exists (owned by whoever shared it); this device never creates it.
    func ensureZone(forLibraryId libraryId: UUID) {
        guard let engine, !SharedLibraryRegistry.shared.isShared(libraryId) else { return }
        let zoneID = CKRecordZone.ID.library(libraryId)
        engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: zoneID))])
        engine.state.add(pendingRecordZoneChanges: [.saveRecord(.record(syncId: libraryId, zoneID: zoneID))])
    }

    /// Enqueues `model` for upload on the next sync pass, on whichever `CKSyncEngine` owns its
    /// library's zone (private, or shared once Phase 10's `acceptShare` has run — see
    /// `SharedLibraryRegistry`). `CKSyncEngine` persists its own pending-change list as part of
    /// its state, so there's no separate pending-change store to maintain here, and this no-ops
    /// harmlessly if neither engine has started (e.g. in unit tests).
    ///
    /// Also where Phase 10's two other cross-cutting concerns land, since every local mutation
    /// funnels through here on its way to CloudKit:
    /// - **Attribution**: `createdBy`/`updatedBy` (reserved, unpopulated since MVP) are set here,
    ///   independent of whether an engine has actually started — so they're populated as soon as
    ///   `CurrentUserStore` has resolved an identity, not only once sync is live.
    /// - **Read-only enforcement**: a participant with read-only permission on a shared library
    ///   has their change accepted locally (SwiftData is local-first per `ARCHITECTURE.md`) but
    ///   rejected right here, before it ever reaches CloudKit — "enforced in the DAL layer"
    ///   (every DAL funnels here) "rejected at the sync layer" (this is that layer), per this
    ///   phase's own plan wording, rather than scattering a permission check across every DAL.
    func recordChanged<T: SyncableRecord>(_ model: T, in context: ModelContext) {
        // Entitlement-suspended: the local edit stands in SwiftData (the app is read-only in
        // the blocked state, so this is only reachable defensively) but nothing is pushed.
        guard !isSuspendedSnapshot else {
            logger.notice("Suppressed local change to \(T.ckRecordType) — sync is entitlement-suspended")
            return
        }
        applyAttribution(to: model)
        guard let syncId = model.syncId, let libraryId = model.resolvedLibraryId(in: context) else { return }

        // Checked before even looking up an engine, deliberately — a read-only participant's
        // write is rejected because of *what the library is*, not because of *whether sync has
        // started*, and ordering it first is what keeps this branch exercisable by a unit test
        // (`engine`/`sharedEngine` are always `nil` there; the permission check isn't gated on
        // either).
        guard SharingPermissionStore.shared.canWrite(toLibraryId: libraryId) else {
            logger.notice("Rejected local change to \(T.ckRecordType) \(syncId) — read-only participant in this shared library")
            SyncStatusStore.shared.recordError("You have read-only access to this shared library — this change won't sync.")
            return
        }

        let isShared = SharedLibraryRegistry.shared.isShared(libraryId)
        guard let targetEngine = isShared ? sharedEngine : engine else { return }

        let ownerName = SharedLibraryRegistry.shared.ownerName(forLibraryId: libraryId) ?? CKCurrentUserDefaultName
        let zoneID = CKRecordZone.ID.library(libraryId, ownerName: ownerName)
        targetEngine.state.add(pendingRecordZoneChanges: [.saveRecord(.record(syncId: syncId, zoneID: zoneID))])
    }

    /// `createdBy` only on first attribution (never overwrites who originally created it);
    /// `updatedBy` every time. Both stay `nil` (today's behavior, unchanged) until
    /// `CurrentUserStore` has resolved an identity — single-user use before Phase 10, or before
    /// the async resolution in `start()` completes, looks identical to MVP.
    private func applyAttribution<T: SyncableRecord>(to model: T) {
        guard let identifier = CurrentUserStore.shared.currentUserIdentifier else { return }
        if model.createdBy == nil {
            model.createdBy = identifier
        }
        model.updatedBy = identifier
    }

    private func ensureZonesForActiveLibraries() {
        guard let modelContainer else { return }
        let context = ModelContext(modelContainer)
        for library in LibraryDAL.fetchActive(in: context) {
            guard let libraryId = library.libraryId else { continue }
            ensureZone(forLibraryId: libraryId)
        }
    }

}

extension SyncEngine: CKSyncEngineDelegate {

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let update):
            let stateScope: SyncStateStoreScope = (syncEngine === sharedEngine) ? .shared : .owned
            SyncStateStore.save(update.stateSerialization, scope: stateScope)

        case .willSendChanges, .willFetchChanges:
            SyncStatusStore.shared.syncWillStart()

        case .didSendChanges, .didFetchChanges:
            SyncStatusStore.shared.syncDidFinish()

        case .fetchedRecordZoneChanges(let changes):
            if isSuspendedSnapshot {
                // Hold, don't apply — a lapsed user's local data is never mutated or deleted
                // out from under them. Replayed verbatim by `resume()`.
                suspensionLock.withLock { bufferedFetchedChanges.append(changes) }
            } else {
                applyFetchedChanges(changes)
                SyncStatusStore.shared.recordSyncedNotes(count: changes.modifications.count, received: true)
            }

        case .sentRecordZoneChanges(let changes):
            await logSentChanges(changes)

        case .accountChange(let change):
            logger.notice("CloudKit account change: \(String(describing: change.changeType))")

        default:
            break
        }
    }

    /// Resolves the whole batch of `CKRecord`s synchronously up front (one `ModelContext`,
    /// used only on this call), then hands `CKSyncEngine`'s async `recordProvider` closure a
    /// plain dictionary lookup — sidesteps needing `ModelContext` (not `Sendable`) inside a
    /// `@Sendable` closure that may be invoked from another context.
    func nextRecordZoneChangeBatch(_ context: CKSyncEngine.SendChangesContext, syncEngine: CKSyncEngine) async -> CKSyncEngine.RecordZoneChangeBatch? {
        guard !isSuspendedSnapshot else { return nil }
        guard let modelContainer else { return nil }
        let scope = context.options.scope
        let changes = syncEngine.state.pendingRecordZoneChanges.filter { scope.contains($0) }
        guard !changes.isEmpty else { return nil }

        let modelContext = ModelContext(modelContainer)
        let recordsByID: [CKRecord.ID: CKRecord] = changes.reduce(into: [:]) { result, change in
            guard case .saveRecord(let recordID) = change else { return }
            result[recordID] = SyncRecordFactory.buildRecord(for: recordID, in: modelContext)
        }

        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: changes) { recordID in
            recordsByID[recordID]
        }
    }

    private func applyFetchedChanges(_ changes: CKSyncEngine.Event.FetchedRecordZoneChanges) {
        guard let modelContainer else { return }
        let modelContext = ModelContext(modelContainer)

        for modification in changes.modifications {
            SyncRecordFactory.applyIncoming(modification.record, in: modelContext)
        }
        for deletion in changes.deletions {
            SyncRecordFactory.applyDeletion(recordID: deletion.recordID, recordType: deletion.recordType, in: modelContext)
        }

        try? modelContext.save()
    }

    /// Feeds S9's sync log/status glyph (`SyncStatusStore`) and logs to `OSLog`. A
    /// `.serverRecordChanged` failure means a genuine conflict — routed to `handleDetectedConflict`,
    /// which decides (per the active `ConflictStrategy`) whether to queue it for S10 or resolve
    /// it automatically right here.
    private func logSentChanges(_ changes: CKSyncEngine.Event.SentRecordZoneChanges) async {
        if !changes.savedRecords.isEmpty {
            logger.notice("Synced \(changes.savedRecords.count) record(s)")
            SyncStatusStore.shared.recordSyncedNotes(count: changes.savedRecords.count, received: false)
        }
        for failure in changes.failedRecordSaves {
            logger.error("Failed to save \(failure.record.recordType) \(failure.record.recordID.recordName): \(failure.error.localizedDescription)")
            if failure.error.code == .serverRecordChanged {
                if let conflict = makeConflict(from: failure) {
                    await handleDetectedConflict(conflict)
                }
            } else {
                SyncStatusStore.shared.recordError(failure.error.localizedDescription)
            }
        }
    }

    private func makeConflict(from failure: CKSyncEngine.Event.SentRecordZoneChanges.FailedRecordSave) -> Conflict? {
        guard let serverRecord = failure.error.serverRecord,
              let syncId = UUID(uuidString: serverRecord.recordID.recordName),
              let libraryId = libraryId(for: serverRecord) else { return nil }
        let clientRecord = failure.error.clientRecord ?? failure.record
        return Conflict(
            recordType: serverRecord.recordType,
            syncId: syncId,
            libraryId: libraryId,
            title: Conflict.displayTitle(for: clientRecord),
            clientRecord: clientRecord,
            serverRecord: serverRecord,
            ancestorRecord: failure.error.ancestorRecord,
            detectedOn: Date()
        )
    }

    /// A `Library` record has no `library` reference field (it's the zone's root) — its own ID
    /// is the library ID; every other record type carries the reference.
    private func libraryId(for record: CKRecord) -> UUID? {
        if record.recordType == Library.ckRecordType {
            return UUID(uuidString: record.recordID.recordName)
        }
        guard let reference = record["library"] as? CKRecord.Reference else { return nil }
        return UUID(uuidString: reference.recordID.recordName)
    }

    /// Keep All Versions always queues for S10. Diff-Merge queues too, but only when there's
    /// actually text to diff — otherwise (and always, for Last-Write-Wins) it resolves
    /// immediately, per this phase's "(...; last-write-wins for non-text)" scope.
    private func handleDetectedConflict(_ conflict: Conflict) async {
        switch ConflictStrategyStore.currentStrategy() {
        case .keepAllVersions:
            ConflictStore.shared.queue(conflict)
            SyncStatusStore.shared.recordConflict(noteTitle: conflict.title)

        case .lastWriteWins:
            await autoResolve(conflict, choice: ConflictResolver.lastWriteWinsChoice(for: conflict))

        case .diffMerge:
            if conflict.hasDiffableContent {
                ConflictStore.shared.queue(conflict)
                SyncStatusStore.shared.recordConflict(noteTitle: conflict.title)
            } else {
                await autoResolve(conflict, choice: ConflictResolver.lastWriteWinsChoice(for: conflict))
            }
        }
    }

    private func autoResolve(_ conflict: Conflict, choice: ConflictResolutionChoice) async {
        let keptLabel = choice == .keepClient ? "this device's edit" : "the synced edit"
        ConflictStore.shared.recordAutoResolution(ConflictAutoResolution(conflict: conflict, kept: choice, keptLabel: keptLabel))
        SyncStatusStore.shared.recordResolvedConflict(noteTitle: conflict.title)
        guard let modelContainer else { return }
        await resolveConflict(conflict, choice: choice, in: ModelContext(modelContainer))
    }

}

/// Lets the entitlement gate (`EntitlementGateViewModel`) pause and resume sync without taking a
/// dependency on the concrete `SyncEngine` singleton — an in-test fake conforms to this instead.
protocol SyncEngineControlling: AnyObject, Sendable {
    func suspend()
    func resume()
}

extension SyncEngine: SyncEngineControlling {

    /// Enter the entitlement-suspended state: stop pushing local changes, stop applying fetched
    /// changes (they buffer). Idempotent.
    func suspend() {
        let didChange = suspensionLock.withLock {
            guard !isEntitlementSuspended else { return false }
            isEntitlementSuspended = true
            return true
        }
        if didChange { logger.notice("Sync suspended — entitlement blocked") }
    }

    /// Leave the suspended state, replay every buffered fetched batch, then catch up. Idempotent.
    func resume() {
        let buffered: [CKSyncEngine.Event.FetchedRecordZoneChanges]? = suspensionLock.withLock {
            guard isEntitlementSuspended else { return nil }
            isEntitlementSuspended = false
            let drained = bufferedFetchedChanges
            bufferedFetchedChanges.removeAll()
            return drained
        }
        guard let buffered else { return }

        logger.notice("Sync resumed — replaying \(buffered.count) buffered fetch batch(es)")
        for changes in buffered {
            applyFetchedChanges(changes)
            SyncStatusStore.shared.recordSyncedNotes(count: changes.modifications.count, received: true)
        }
        Task { await syncNow() }
    }
}
