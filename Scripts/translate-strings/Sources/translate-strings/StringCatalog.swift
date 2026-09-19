// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  StringCatalog.swift
//  translate-strings
//

import Foundation

/// A thin, forgiving wrapper over an `.xcstrings` file's JSON. Deliberately **not** a strict
/// `Codable` model: Xcode's own schema carries fields this tool never needs to touch
/// (`extractionState`, `shouldTranslate`, width `substitutions`, plural `variations`, …), and a
/// fixed-shape struct would silently drop them on re-serialization the moment this tool writes
/// the file back — corrupting the catalog for Xcode. Working over `[String: Any]` preserves
/// everything this tool doesn't explicitly touch.
struct StringCatalog {

    private(set) var root: [String: Any]
    let url: URL

    /// One entry from the catalog's `"strings"` dictionary — a source key plus everything
    /// Xcode has recorded about it.
    struct Entry {
        let key: String
        var raw: [String: Any]

        var comment: String? { raw["comment"] as? String }

        /// R4: a one-time manual review pass over ambiguous short UI strings ("Promote", "Fit
        /// to Screen") flags the ones it can't yet resolve by writing `NEEDS-CONTEXT: ...` into
        /// the comment itself, rather than adding a non-standard field to the `.xcstrings`
        /// schema. The translate script refuses to translate a key flagged this way.
        var needsContext: Bool {
            comment?.hasPrefix("NEEDS-CONTEXT") ?? false
        }

        /// `true` when this entry uses plural `variations` rather than a flat `stringUnit`.
        /// Empirically confirmed (Phase 2.3): `xcstringstool` only compiles a real
        /// `NSStringPluralRuleType` `.stringsdict` entry when `variations.plural` is nested
        /// *inside* a language's `localizations.<lang>` — a top-level `variations` key (this
        /// project's own original, untested assumption, also matched by Apple's own on-disk
        /// examples out of context) silently compiles to a single flattened string, discarding
        /// every plural category but one. This tool deliberately does not attempt to
        /// auto-translate a plural variant set (getting a CLDR plural category wrong silently
        /// is worse than leaving it for a human/Phase-2 pass).
        var isPluralVariant: Bool {
            if raw["variations"] != nil { return true }
            for value in localizations.values {
                if let loc = value as? [String: Any], loc["variations"] != nil { return true }
            }
            return false
        }

        var localizations: [String: Any] {
            get { (raw["localizations"] as? [String: Any]) ?? [:] }
            set { raw["localizations"] = newValue }
        }

        /// The source-language (`en`) literal text for this key — the key itself, for a
        /// standard `.xcstrings` catalog with no separate `stringUnit` override for the source
        /// language (the common case; SwiftUI's `Text("literal")` extraction uses the literal
        /// as the key).
        var sourceText: String { key }

        func translatedValue(for locale: String) -> String? {
            guard let loc = localizations[locale] as? [String: Any],
                  let unit = loc["stringUnit"] as? [String: Any] else { return nil }
            return unit["value"] as? String
        }

        func state(for locale: String) -> String? {
            guard let loc = localizations[locale] as? [String: Any],
                  let unit = loc["stringUnit"] as? [String: Any] else { return nil }
            return unit["state"] as? String
        }

        mutating func setTranslation(_ value: String, locale: String, state: String = "translated") {
            var locs = localizations
            locs[locale] = ["stringUnit": ["state": state, "value": value]]
            localizations = locs
        }
    }

    static func load(from url: URL) throws -> StringCatalog {
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw CatalogError.malformed(url)
        }
        return StringCatalog(root: json, url: url)
    }

    var sourceLanguage: String { (root["sourceLanguage"] as? String) ?? "en" }

    var entries: [Entry] {
        let strings = (root["strings"] as? [String: Any]) ?? [:]
        return strings.map { key, value in
            Entry(key: key, raw: (value as? [String: Any]) ?? [:])
        }.sorted { $0.key < $1.key }
    }

    mutating func upsert(_ entry: Entry) {
        var strings = (root["strings"] as? [String: Any]) ?? [:]
        strings[entry.key] = entry.raw
        root["strings"] = strings
    }

    /// Adds `key` as a brand-new catalog entry if it isn't present yet — used by the (future)
    /// extraction step; harmless no-op if the key already exists.
    mutating func ensureKeyExists(_ key: String, comment: String?) {
        var strings = (root["strings"] as? [String: Any]) ?? [:]
        guard strings[key] == nil else { return }
        var entry: [String: Any] = ["extractionState": "manual"]
        if let comment, !comment.isEmpty { entry["comment"] = comment }
        strings[key] = entry
        root["strings"] = strings
    }

    /// Writes back with Xcode's own on-disk conventions: sorted keys, 2-space indent, no
    /// escaped slashes — so a re-run's diff shows only genuine content changes, not formatting
    /// noise (this file is meant to be committed and diffed, per Phase 0.5's own description).
    func write() throws {
        var options: JSONSerialization.WritingOptions = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        if #available(macOS 13, *) { options.insert(.withoutEscapingSlashes) }
        let data = try JSONSerialization.data(withJSONObject: root, options: options)
        try data.write(to: url, options: .atomic)
    }

    enum CatalogError: Error, CustomStringConvertible {
        case malformed(URL)
        var description: String {
            switch self {
            case .malformed(let url): return "Could not parse String Catalog at \(url.path) as JSON."
            }
        }
    }

}
