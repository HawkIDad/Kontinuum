// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SharedLibraryRegistryTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

/// Each test uses its own `UserDefaults` suite, mirroring `LibraryDALTests`'s existing
/// injected-defaults convention for `LibraryDAL.selectedLibraryId`.
struct SharedLibraryRegistryTests {

    private func makeDefaults(suiteName: String = #function) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func aLibraryNeverMarkedSharedReportsFalse() {
        let registry = SharedLibraryRegistry(defaults: makeDefaults())
        #expect(registry.isShared(UUID()) == false)
        #expect(registry.ownerName(forLibraryId: UUID()) == nil)
    }

    @Test func markSharedRecordsBothTheFlagAndTheOwnerName() {
        let registry = SharedLibraryRegistry(defaults: makeDefaults())
        let libraryId = UUID()
        registry.markShared(libraryId, ownerName: "_owner123")

        #expect(registry.isShared(libraryId))
        #expect(registry.ownerName(forLibraryId: libraryId) == "_owner123")
    }

    @Test func unmarkSharedReversesMarkShared() {
        let registry = SharedLibraryRegistry(defaults: makeDefaults())
        let libraryId = UUID()
        registry.markShared(libraryId, ownerName: "_owner123")
        registry.unmarkShared(libraryId)

        #expect(registry.isShared(libraryId) == false)
        #expect(registry.ownerName(forLibraryId: libraryId) == nil)
    }

    @Test func stateSurvivesAcrossInstancesSharingTheSameDefaults() {
        let defaults = makeDefaults()
        let libraryId = UUID()
        SharedLibraryRegistry(defaults: defaults).markShared(libraryId, ownerName: "_owner123")

        let reloaded = SharedLibraryRegistry(defaults: defaults)
        #expect(reloaded.isShared(libraryId))
        #expect(reloaded.ownerName(forLibraryId: libraryId) == "_owner123")
    }

    @Test func marksSharedForMultipleLibrariesIndependently() {
        let registry = SharedLibraryRegistry(defaults: makeDefaults())
        let firstLibraryId = UUID()
        let secondLibraryId = UUID()
        registry.markShared(firstLibraryId, ownerName: "_ownerA")
        registry.markShared(secondLibraryId, ownerName: "_ownerB")

        #expect(registry.ownerName(forLibraryId: firstLibraryId) == "_ownerA")
        #expect(registry.ownerName(forLibraryId: secondLibraryId) == "_ownerB")
    }

}
