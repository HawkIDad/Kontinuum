// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LocalePreferenceStore.swift
//  NoteBytez
//

import Foundation

/// UserDefaults-backed, matching `TemplateOnboardingStore`/`ConflictStrategyStore`'s pattern.
/// Owns the in-app language override (`AppleLanguages`) and whether the first-launch language
/// prompt has been shown. Per NoteBytez20260823v2-MultiLanguage.md Phase 5, decisions G4/G4a/G4b.
enum LocalePreferenceStore {

    /// The exact key iOS itself reads at process launch to decide the app's preferred
    /// localization — `setPreferredLanguageCode`/`reapplyPreferredLanguage` write here (as a
    /// one-element array) to actually take effect.
    private static let appleLanguagesKey = "AppleLanguages"
    /// The source of truth this store reads back from — deliberately **not** `AppleLanguages`
    /// itself. `AppleLanguages` also lives in `NSGlobalDomain`, which every `UserDefaults`
    /// instance (including a fresh test suite) consults as a read fallback — so a device/
    /// simulator's own ambient language (always non-empty) would otherwise make "nothing
    /// stored" indistinguishable from "the device happens to be English", both in tests and in
    /// the real Settings UI (which would then wrongly show a language as explicitly selected
    /// that the user never actually picked). A private key has no such collision.
    private static let preferredLanguageCodeKey = "preferredLanguageCode"
    private static let hasPromptedForLanguageKey = "hasPromptedForLanguage"

    /// `nil` means "System default" — no override, iOS's own per-app Language setting (or the
    /// device's own language) decides.
    static func preferredLanguageCode(in defaults: UserDefaults = .standard) -> String? {
        defaults.string(forKey: preferredLanguageCodeKey)
    }

    /// Setting `nil` clears the override entirely (removes `AppleLanguages`, not an empty array)
    /// so control genuinely returns to iOS rather than pinning an empty preference.
    static func setPreferredLanguageCode(_ code: String?, in defaults: UserDefaults = .standard) {
        defaults.set(code, forKey: preferredLanguageCodeKey)
        applyToAppleLanguages(code, in: defaults)
    }

    private static func applyToAppleLanguages(_ code: String?, in defaults: UserDefaults) {
        if let code {
            defaults.set([code], forKey: appleLanguagesKey)
        } else {
            defaults.removeObject(forKey: appleLanguagesKey)
        }
    }

    /// Re-writes whatever is already stored back into `AppleLanguages` — a deliberate no-op
    /// when nothing has changed. Called once at the very start of `NoteBytezApp.init` (5.6),
    /// before the `ModelContainer`/`WindowGroup` are built, as a defensive guard against a
    /// preferences-flush race between a Settings change and a subsequent cold launch. This
    /// can't be verified by a test (it's about disk-flush timing across process launches, not
    /// in-process state), so it's documented here rather than claimed as tested.
    static func reapplyPreferredLanguage(in defaults: UserDefaults = .standard) {
        setPreferredLanguageCode(preferredLanguageCode(in: defaults), in: defaults)
    }

    static func hasPromptedForLanguage(in defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: hasPromptedForLanguageKey)
    }

    static func markPromptedForLanguage(in defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: hasPromptedForLanguageKey)
    }

    /// Test/debug-only reset, mirroring `TemplateOnboardingStore.reset(in:)`.
    static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: appleLanguagesKey)
        defaults.removeObject(forKey: preferredLanguageCodeKey)
        defaults.removeObject(forKey: hasPromptedForLanguageKey)
    }

}
