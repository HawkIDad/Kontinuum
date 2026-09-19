// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Placeholders.swift
//  translate-strings
//

import Foundation

/// Phase 0.6 (G15) — every translated value must carry the exact placeholder *multiset* of its
/// source. A translator dropping, duplicating, or mistyping a `%@`/`%1$@`/`%lld` placeholder is
/// a silent runtime crash or garbled string waiting to happen; this is a hard CI error, never a
/// warning (unlike the drift report).
enum Placeholders {

    /// Matches both positional (`%1$@`, `%2$lld`) and simple (`%@`, `%d`, `%lld`, `%.2f`, `%%`)
    /// `String(format:)`-style specifiers: `%`, an optional `N$` position, optional flags/width/
    /// precision, an optional length modifier (`l`, `ll`, `h`, `hh`, `z`, `q`), and a conversion
    /// character.
    private static let formatSpecifierPattern = try! NSRegularExpression(
        pattern: #"%(\d+\$)?[-+0# ]*\d*(\.\d+)?(hh|h|ll|l|q|z)?[@dioxXufFeEgGcCsSpaA%]"#
    )

    /// Matches SwiftUI's String-Catalog-native interpolation placeholders, `%arg` markers Xcode
    /// itself writes for `"\(count) notes"`-style keys: `%lld`, `%@`, and the catalog's own
    /// `%#@variableName@` plural-substitution marker.
    private static let substitutionMarkerPattern = try! NSRegularExpression(
        pattern: #"%#@[A-Za-z0-9_]+@"#
    )

    /// The multiset of placeholder tokens in `text`, order-independent (a translator is allowed
    /// to reorder `%1$@ in %2$@` to `%2$@ %1$@`, per Phase 2.4 — reordering is not a mismatch).
    static func tokens(in text: String) -> [String: Int] {
        var counts: [String: Int] = [:]
        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)

        for regex in [substitutionMarkerPattern, formatSpecifierPattern] {
            for match in regex.matches(in: text, range: fullRange) {
                let token = nsText.substring(with: match.range)
                counts[token, default: 0] += 1
            }
        }
        return counts
    }

    /// Whether `translated` preserves every placeholder `source` has, exactly as many times
    /// each (a positional specifier like `%1$@` is a distinct token from `%2$@` — a translation
    /// that keeps the *count* but drops one specific index is still a mismatch).
    static func isSafe(source: String, translated: String) -> Bool {
        tokens(in: source) == tokens(in: translated)
    }

    struct Mismatch: CustomStringConvertible {
        let key: String
        let locale: String
        let sourceTokens: [String: Int]
        let translatedTokens: [String: Int]

        var description: String {
            "Placeholder mismatch for \"\(key)\" (\(locale)): source has \(sourceTokens), translation has \(translatedTokens)"
        }
    }

}
