// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SupportedLocales.swift
//  NoteBytez
//

import Foundation

/// One locale this *build* has actually shipped translations for — endonym is the language's
/// own name for itself ("Deutsch", "日本語"), never translated into the current UI language.
struct SupportedLocale: Identifiable, Equatable {
    /// BCP-47 identifier, matching `NoteBytez20260823v2-MultiLanguage.md` G8's canonical list
    /// (e.g. `en-US`, `pt-BR`, `zh-Hans`) — also what gets written into `AppleLanguages`.
    let id: String
    let endonym: String
}

/// The single source of truth for "which locales has this build actually shipped" — consumed by
/// both the first-launch prompt and the Settings picker so neither ever offers a locale with no
/// real translations (G4b: "picking a language with zero translated strings would look broken,
/// not localized"). Starts with just `en-US`; each Language Rollout tier's "Ship" task
/// (Phases 6–11) appends that tier's locales here once real translations for the *general app
/// UI* — not just isolated seed content — actually exist.
enum SupportedLocales {

    static let all: [SupportedLocale] = [
        SupportedLocale(id: "en-US", endonym: "English (United States)"),
        // Phase 7 (Language Rollout Phase 2 — Major Western European), shipped 2026-09-15.
        SupportedLocale(id: "en-GB", endonym: "English (United Kingdom)"),
        SupportedLocale(id: "es", endonym: "Español"),
        SupportedLocale(id: "fr", endonym: "Français"),
        SupportedLocale(id: "de", endonym: "Deutsch"),
        SupportedLocale(id: "it", endonym: "Italiano"),
        SupportedLocale(id: "pt-BR", endonym: "Português (Brasil)"),
        // Phase 8 (Language Rollout Phase 3 — Dutch, Nordics & Greek), shipped 2026-09-16.
        SupportedLocale(id: "nl", endonym: "Nederlands"),
        SupportedLocale(id: "da", endonym: "Dansk"),
        SupportedLocale(id: "el", endonym: "Ελληνικά"),
        SupportedLocale(id: "sv", endonym: "Svenska"),
        SupportedLocale(id: "fi", endonym: "Suomi"),
        SupportedLocale(id: "nb", endonym: "Norsk bokmål"),
    ]

    /// The device's own language if it's in `all`, else the first (always `en-US`) entry — G4b's
    /// first-launch pre-selection rule. Matches by language subtag only (`"de"` from `"de-AT"`
    /// matches a shipped `"de"`-prefixed entry), since the device's exact region variant rarely
    /// lines up with the one this app ships.
    ///
    /// Known limitation: subtag-only matching can't distinguish `en-US` from `en-GB` — both have
    /// subtag `"en"`, so a British device also matches `en-US` (the first `"en"`-prefixed entry
    /// in `all`). Harmless today (`en-GB` carries zero catalog overrides — see Phase 7.5 — so the
    /// two are byte-identical), but revisit with a real region-aware match once a locale pair
    /// actually diverges (e.g. a future `zh-Hans`/`zh-Hant`).
    static func matchingDevice(languageCode: String = Locale.current.language.languageCode?.identifier ?? "en") -> SupportedLocale {
        all.first { $0.languageSubtag == languageCode } ?? all[0]
    }

}

private extension SupportedLocale {
    var languageSubtag: String {
        id.split(separator: "-").first.map(String.init) ?? id
    }
}
