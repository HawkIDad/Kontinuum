// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CurrentUserStoreTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

/// Covers the synchronous cache/persistence half of `CurrentUserStore` — `resolveCurrentUser`
/// itself needs a live `CKContainer`, out of scope here (same class of gap as the rest of
/// Phase 10's live-CloudKit paths). Each test uses its own `UserDefaults` suite, never `.standard`,
/// so these never interact with a real device's persisted state or each other.
struct CurrentUserStoreTests {

    private func makeDefaults(suiteName: String = #function) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    @Test func startsWithNoIdentifierWhenNothingWasEverPersisted() {
        let store = CurrentUserStore(defaults: makeDefaults())
        #expect(store.currentUserIdentifier == nil)
    }

    @Test func setStoresTheIdentifierSynchronously() {
        let store = CurrentUserStore(defaults: makeDefaults())
        store.set("_abc123")
        #expect(store.currentUserIdentifier == "_abc123")
    }

    @Test func identifierSurvivesAcrossInstancesSharingTheSameDefaults() {
        let defaults = makeDefaults()
        CurrentUserStore(defaults: defaults).set("_abc123")

        let reloaded = CurrentUserStore(defaults: defaults)
        #expect(reloaded.currentUserIdentifier == "_abc123")
    }

    @Test func setNilClearsAPreviouslyPersistedIdentifier() {
        let defaults = makeDefaults()
        let store = CurrentUserStore(defaults: defaults)
        store.set("_abc123")
        store.set(nil)

        #expect(store.currentUserIdentifier == nil)
        #expect(CurrentUserStore(defaults: defaults).currentUserIdentifier == nil)
    }

}
