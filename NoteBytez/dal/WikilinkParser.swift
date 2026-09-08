// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  WikilinkParser.swift
//  Kontinuum
//

import Foundation

/// `[[Title]]` extraction/rewriting for backlink indexing and rename propagation, plus the
/// autocomplete heuristics for the in-progress `[[query` a user is typing.
///
/// This pattern is intentionally kept in sync with (but separate from) MarkdownG9's own
/// wikilink-to-link rewrite in `MDProcessor` — that one is about rendering, this one is about
/// indexing/editing, and the two live in different targets.
enum WikilinkParser {

    private static let wikilinkPattern = try! NSRegularExpression(pattern: #"\[\[([^\]]+)\]\]"#)

    /// Titles only — a `[[Title#Heading]]` section link's `#Heading` suffix is stripped, so
    /// document-level backlinks and rename propagation keep treating it as a link to `Title`.
    static func extractTitles(from content: String) -> [String] {
        let nsContent = content as NSString
        let matches = wikilinkPattern.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
        return matches.map {
            let raw = nsContent.substring(with: $0.range(at: 1)).trimmingCharacters(in: .whitespaces)
            return parseTarget(raw).title
        }
    }

    /// Splits a `[[ ]]` target on its first `#` into the document title and, if present, the
    /// section heading — the sole difference between a plain wikilink and a section link.
    static func parseTarget(_ raw: String) -> (title: String, heading: String?) {
        guard let hashIndex = raw.firstIndex(of: "#") else {
            return (title: raw, heading: nil)
        }
        return (title: String(raw[raw.startIndex..<hashIndex]), heading: String(raw[raw.index(after: hashIndex)...]))
    }

    /// Rewrites every `[[oldTitle]]` (or `[[oldTitle#Heading]]`) occurrence (case-insensitive)
    /// to `[[newTitle]]`/`[[newTitle#Heading]]`, preserving any `#Heading` suffix untouched.
    static func renamingWikilinks(from oldTitle: String, to newTitle: String, in content: String) -> String {
        let escapedOldTitle = NSRegularExpression.escapedPattern(for: oldTitle)
        guard let regex = try? NSRegularExpression(pattern: "\\[\\[\(escapedOldTitle)(#[^\\]]*)?\\]\\]", options: [.caseInsensitive]) else {
            return content
        }

        let range = NSRange(content.startIndex..., in: content)
        let template = "[[\(NSRegularExpression.escapedTemplate(for: newTitle))$1]]"
        return regex.stringByReplacingMatches(in: content, range: range, withTemplate: template)
    }

    /// The in-progress query text for an unclosed `[[query` at the end of `content`, or `nil`
    /// if there's no active wikilink being typed. Deliberately a simple end-of-string
    /// heuristic rather than tracking the text editor's real cursor position — SwiftUI's
    /// `TextEditor` selection APIs are fiddly, and this covers the normal single-cursor
    /// typing flow without that complexity.
    static func activeQuery(in content: String) -> String? {
        guard let openRange = content.range(of: "[[", options: .backwards) else { return nil }
        let afterOpen = content[openRange.upperBound...]
        guard !afterOpen.contains("]]"), !afterOpen.contains("\n"), !afterOpen.contains("[") else { return nil }
        return String(afterOpen)
    }

    /// Replaces the trailing in-progress `[[query` (as found by `activeQuery`) with a
    /// completed `[[title]] ` wikilink. No-op if there's no active query.
    static func applying(title: String, to content: String) -> String {
        guard let openRange = content.range(of: "[[", options: .backwards) else { return content }
        let afterOpen = content[openRange.upperBound...]
        guard !afterOpen.contains("]]"), !afterOpen.contains("\n"), !afterOpen.contains("[") else { return content }
        return content.replacingCharacters(in: openRange.lowerBound..<content.endIndex, with: "[[\(title)]] ")
    }

    /// Simple subsequence fuzzy match: every character of `query`, in order, appears
    /// somewhere in `candidate` (not necessarily contiguous) — the same lightweight
    /// technique used by editor quick-open pickers.
    static func fuzzyMatches(_ candidate: String, query: String) -> Bool {
        guard !query.isEmpty else { return true }

        var candidateIterator = candidate.lowercased().makeIterator()
        for queryCharacter in query.lowercased() {
            var found = false
            while let candidateCharacter = candidateIterator.next() {
                if candidateCharacter == queryCharacter {
                    found = true
                    break
                }
            }
            if !found { return false }
        }
        return true
    }

}
