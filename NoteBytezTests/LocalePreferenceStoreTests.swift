// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LocalePreferenceStoreTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct LocalePreferenceStoreTests {

    /// `defaults.description` (used by every other `*StoreTests` in this suite to name its own
    /// persistent domain) happens to equal the suite name passed to `UserDefaults(suiteName:)`,
    /// which is what makes `removePersistentDomain(forName:)` work below.
    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "LocalePreferenceStoreTests-\(UUID().uuidString)")!
        defaults.removePersistentDomain(forName: defaults.description)
        return defaults
    }

    /// `AppleLanguages` also lives in `NSGlobalDomain`, which every `UserDefaults` instance
    /// (any suite, including a fresh test one) falls back to on read — so
    /// `defaults.array(forKey: "AppleLanguages")` can never reliably assert "this key is unset"
    /// here, only "this key resolves to X" for an X this suite itself wrote. To check what this
    /// suite's *own* domain actually holds (ignoring the global-domain fallback), go through
    /// `persistentDomain(forName:)` instead — this is the discovery documented on
    /// `LocalePreferenceStore.preferredLanguageCodeKey`.
    private func ownAppleLanguagesValue(_ defaults: UserDefaults) -> [String]? {
        // `persistentDomain(forName:)` reflects the synced/on-disk domain, not just the
        // in-memory cache `set(_:forKey:)` updates immediately — without this, a value just
        // written reads back as absent here even though `preferredLanguageCode(in:)` (which
        // reads a different key entirely) already sees it correctly.
        defaults.synchronize()
        return defaults.persistentDomain(forName: defaults.description)?["AppleLanguages"] as? [String]
    }

    @Test func preferredLanguageCodeIsNilWhenNothingIsStored() {
        let defaults = makeDefaults()
        #expect(LocalePreferenceStore.preferredLanguageCode(in: defaults) == nil)
    }

    @Test func settingAPreferredLanguageWritesAppleLanguagesAndRoundTrips() {
        let defaults = makeDefaults()
        LocalePreferenceStore.setPreferredLanguageCode("de", in: defaults)

        // Unlike the "cleared" case below, this read is unambiguous even through the
        // `NSGlobalDomain` fallback: the simulator's own ambient language is never "de" here,
        // so seeing it back proves this store's own write is what's taking effect.
        #expect((defaults.array(forKey: "AppleLanguages") as? [String]) == ["de"])
        #expect(LocalePreferenceStore.preferredLanguageCode(in: defaults) == "de")
    }

    @Test func settingNilClearsTheOverrideEntirelyRatherThanStoringAnEmptyArray() {
        let defaults = makeDefaults()
        LocalePreferenceStore.setPreferredLanguageCode("de", in: defaults)

        LocalePreferenceStore.setPreferredLanguageCode(nil, in: defaults)

        #expect(ownAppleLanguagesValue(defaults) == nil, "this app's own domain must have the key removed, not left as []")
        #expect(LocalePreferenceStore.preferredLanguageCode(in: defaults) == nil)
    }

    @Test func settingANewPreferenceOverwritesThePreviousOne() {
        let defaults = makeDefaults()
        LocalePreferenceStore.setPreferredLanguageCode("de", in: defaults)
        LocalePreferenceStore.setPreferredLanguageCode("en-US", in: defaults)
        #expect(LocalePreferenceStore.preferredLanguageCode(in: defaults) == "en-US")
    }

    @Test func reapplyPreferredLanguageIsANoOpThatPreservesWhateverIsStored() {
        let defaults = makeDefaults()
        LocalePreferenceStore.reapplyPreferredLanguage(in: defaults)
        #expect(LocalePreferenceStore.preferredLanguageCode(in: defaults) == nil)

        LocalePreferenceStore.setPreferredLanguageCode("de", in: defaults)
        LocalePreferenceStore.reapplyPreferredLanguage(in: defaults)
        #expect(LocalePreferenceStore.preferredLanguageCode(in: defaults) == "de")
    }

    @Test func hasPromptedForLanguageStartsFalseAndFlipsToTrueOnceMarked() {
        let defaults = makeDefaults()
        #expect(LocalePreferenceStore.hasPromptedForLanguage(in: defaults) == false)

        LocalePreferenceStore.markPromptedForLanguage(in: defaults)

        #expect(LocalePreferenceStore.hasPromptedForLanguage(in: defaults) == true)
    }

    @Test func resetClearsBothThePreferenceAndThePromptedFlag() {
        let defaults = makeDefaults()
        LocalePreferenceStore.setPreferredLanguageCode("de", in: defaults)
        LocalePreferenceStore.markPromptedForLanguage(in: defaults)

        LocalePreferenceStore.reset(in: defaults)

        #expect(LocalePreferenceStore.preferredLanguageCode(in: defaults) == nil)
        #expect(LocalePreferenceStore.hasPromptedForLanguage(in: defaults) == false)
    }

}
