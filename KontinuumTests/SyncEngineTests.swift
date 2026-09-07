// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncEngineTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import CloudKit
import Foundation
@testable import Kontinuum

/// Covers the two cross-cutting concerns Phase 10 added to `SyncEngine.recordChanged` —
/// attribution and read-only enforcement — both deliberately placed *before* the
/// `engine`/`sharedEngine` nil-check so they're exercisable here without a live `CKSyncEngine`
/// (see that method's own doc comment). Everything past that point (actually enqueuing a pending
/// change) needs a started engine and stays untested here, same as the rest of `SyncEngine` —
/// no `SyncEngineTests` existed before this phase for exactly that reason.
///
/// `.serialized`: every test reaches through `SyncEngine.shared` into the real
/// `CurrentUserStore.shared`/`SharingPermissionStore.shared` singletons (there's no injectable
/// seam — `SyncEngine` is itself a bare singleton by design, per its own doc comment). Running
/// this suite's tests concurrently would race on that shared mutable state; each test restores
/// what it changed, but only serialization makes that safe.
@Suite(.serialized)
struct SyncEngineTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(for: Library.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    @Test func recordChangedSetsCreatedByAndUpdatedByWhenACurrentUserIsResolved() throws {
        let context = try makeContext()
        let library = Library(name: "Research")
        context.insert(library)

        let previousIdentifier = CurrentUserStore.shared.currentUserIdentifier
        defer { CurrentUserStore.shared.set(previousIdentifier) }
        CurrentUserStore.shared.set("_testUser")

        SyncEngine.shared.recordChanged(library, in: context)

        #expect(library.createdBy == "_testUser")
        #expect(library.updatedBy == "_testUser")
    }

    @Test func recordChangedNeverOverwritesAnExistingCreatedBy() throws {
        let context = try makeContext()
        let library = Library(name: "Research")
        library.createdBy = "_originalAuthor"
        context.insert(library)

        let previousIdentifier = CurrentUserStore.shared.currentUserIdentifier
        defer { CurrentUserStore.shared.set(previousIdentifier) }
        CurrentUserStore.shared.set("_testUser")

        SyncEngine.shared.recordChanged(library, in: context)

        #expect(library.createdBy == "_originalAuthor")
        #expect(library.updatedBy == "_testUser")
    }

    @Test func recordChangedLeavesAttributionNilWhenNoCurrentUserIsResolved() throws {
        let context = try makeContext()
        let library = Library(name: "Research")
        context.insert(library)

        let previousIdentifier = CurrentUserStore.shared.currentUserIdentifier
        defer { CurrentUserStore.shared.set(previousIdentifier) }
        CurrentUserStore.shared.set(nil)

        SyncEngine.shared.recordChanged(library, in: context)

        #expect(library.createdBy == nil)
        #expect(library.updatedBy == nil)
    }

    @Test func recordChangedOnAReadOnlyLibraryReportsASyncErrorAndDoesNotThrow() throws {
        let context = try makeContext()
        let library = Library(name: "Shared Research")
        context.insert(library)
        guard let libraryId = library.libraryId else { Issue.record("Library has no id"); return }

        SharingPermissionStore.shared.setPermission(.readOnly, forLibraryId: libraryId)
        defer { SharingPermissionStore.shared.update(forLibraryId: libraryId, share: nil) }

        let previousErrorCount = SyncStatusStore.shared.logEntries.count
        SyncEngine.shared.recordChanged(library, in: context)

        #expect(SyncStatusStore.shared.logEntries.count == previousErrorCount + 1)
        #expect(SyncStatusStore.shared.dismissibleError?.message.contains("read-only") == true)
    }

    @Test func recordChangedOnAReadWriteLibraryDoesNotReportASyncError() throws {
        let context = try makeContext()
        let library = Library(name: "Shared Research")
        context.insert(library)
        guard let libraryId = library.libraryId else { Issue.record("Library has no id"); return }

        SharingPermissionStore.shared.setPermission(.readWrite, forLibraryId: libraryId)
        defer { SharingPermissionStore.shared.update(forLibraryId: libraryId, share: nil) }

        let previousErrorCount = SyncStatusStore.shared.logEntries.count
        SyncEngine.shared.recordChanged(library, in: context)

        #expect(SyncStatusStore.shared.logEntries.count == previousErrorCount)
    }

    // MARK: - Entitlement suspension (NoteBytez20260907v1-Security.md Phase 5)
    //
    // In this same serialized suite deliberately: `suspend()` flips shared `SyncEngine.shared`
    // state, and the attribution tests above would see their `recordChanged` calls suppressed
    // if a suspension test ran concurrently. Every test here restores the unsuspended state.

    @Test func suspendedRecordChangedIsSuppressedBeforeEvenTheReadOnlyCheck() throws {
        let context = try makeContext()
        let library = Library(name: "Shared Research")
        context.insert(library)
        guard let libraryId = library.libraryId else { Issue.record("Library has no id"); return }

        SharingPermissionStore.shared.setPermission(.readOnly, forLibraryId: libraryId)
        defer { SharingPermissionStore.shared.update(forLibraryId: libraryId, share: nil) }

        SyncEngine.shared.suspend()
        defer { SyncEngine.shared.resume() }

        let previousErrorCount = SyncStatusStore.shared.logEntries.count
        SyncEngine.shared.recordChanged(library, in: context)

        // Suppressed before the read-only rejection is reached, so nothing is recorded.
        #expect(SyncStatusStore.shared.logEntries.count == previousErrorCount)
    }

    @Test func resumeRestoresNormalChangeHandling() throws {
        let context = try makeContext()
        let library = Library(name: "Shared Research")
        context.insert(library)
        guard let libraryId = library.libraryId else { Issue.record("Library has no id"); return }

        SharingPermissionStore.shared.setPermission(.readOnly, forLibraryId: libraryId)
        defer { SharingPermissionStore.shared.update(forLibraryId: libraryId, share: nil) }

        SyncEngine.shared.suspend()
        SyncEngine.shared.resume()

        let previousErrorCount = SyncStatusStore.shared.logEntries.count
        SyncEngine.shared.recordChanged(library, in: context)

        // Back to normal: the read-only participant's write is rejected and recorded again.
        #expect(SyncStatusStore.shared.logEntries.count == previousErrorCount + 1)
    }

    @Test func suspendAndResumeAreIdempotent() {
        SyncEngine.shared.resume() // no-op when not suspended
        SyncEngine.shared.suspend()
        SyncEngine.shared.suspend()
        SyncEngine.shared.resume()
        SyncEngine.shared.resume()
        // Reaching here without a crash / double-drain is the assertion; leave unsuspended.
        #expect(Bool(true))
    }

}
