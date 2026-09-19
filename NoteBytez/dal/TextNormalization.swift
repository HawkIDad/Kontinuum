// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TextNormalization.swift
//  NoteBytez
//

import Foundation

/// Shared Unicode/locale-correctness helpers (`Docs/Plans/NoteBytez20260823v2- HOLD
/// -MultiLanguage.md` Phase 1, decision G17) — applied at every text-ingest boundary so
/// canonicalization, sorting, and matching behave consistently regardless of which language a
/// document was written in.
enum TextNormalization {

    /// NFC (canonical composition). Applied wherever text is persisted (`DocumentDAL.create` /
    /// `updateContent` / `updateTitle`), so a decomposed (NFD — some IMEs and paste sources
    /// produce this) and precomposed (NFC) form of the same visible text are stored identically
    /// and never silently diverge downstream (sort order, tag/wikilink identity, search).
    static func normalized(_ text: String) -> String {
        text.precomposedStringWithCanonicalMapping
    }

    /// A single, locale-*invariant* casing rule for identity/canonicalization purposes (tag
    /// dedupe) — deliberately not `Locale.current`, so the same input folds to the same
    /// canonical form regardless of which language the device is set to. Using the current
    /// locale here would let Turkish's dotted-İ/dotless-ı tailoring make two users' identical
    /// tag text fold to two different canonical strings.
    static func invariantLowercased(_ text: String) -> String {
        text.lowercased(with: Locale(identifier: "en_US_POSIX"))
    }

}

extension String {

    /// Case- *and* diacritic-insensitive containment — `"cafe"` matches `"café"`. Distinct from
    /// `localizedCaseInsensitiveContains`, which still requires the accent to match exactly.
    /// For search/autocomplete matching only; never used for canonicalization/identity, where
    /// diacritics are meaningful (a tag's spelling shouldn't be silently altered).
    func containsIgnoringCaseAndDiacritics(_ other: String) -> Bool {
        guard !other.isEmpty else { return false }
        return range(of: other, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

}
