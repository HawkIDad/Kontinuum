// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagParser.swift
//  NoteBytez
//

import Foundation

/// `#tag` and YAML frontmatter `tags:` extraction/canonicalization for tag indexing, plus the
/// autocomplete heuristics for the in-progress `#query` a user is typing.
///
/// This pattern is intentionally kept in sync with (but separate from) MarkdownG9's own
/// `#tag`-to-link rewrite in `MDProcessor` — that one is about rendering, this one is about
/// indexing/editing, and the two live in different targets. Mirrors `WikilinkParser`.
enum TagParser {

    /// Requires a word character immediately after `#` (no space), so a real Markdown
    /// heading (`# Heading`) is never mistaken for a tag. Excludes `#` preceded by another
    /// `#` or a word character, so `##Subheading`-style headings and mid-word `#`s are
    /// left alone. Flat only — no nested/hierarchical tags in MVP.
    private static let inlineTagPattern = try! NSRegularExpression(pattern: #"(?<![#\w])#([A-Za-z0-9][A-Za-z0-9_-]*)"#)

    static func extractInlineTags(from content: String) -> [String] {
        let nsContent = content as NSString
        let matches = inlineTagPattern.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
        return matches.map { canonicalize(nsContent.substring(with: $0.range(at: 1))) }
    }

    /// Parses the `tags:` key out of a leading `---`-delimited YAML frontmatter block, in any
    /// of its three common forms: flow list (`tags: [a, b]`), block list (`tags:` followed by
    /// `- a` / `- b` lines), or a single inline value (`tags: a`). Not a general YAML parser —
    /// only what `tags:` needs.
    static func extractFrontmatterTags(from content: String) -> [String] {
        guard let block = frontmatterBlock(in: content) else { return [] }
        let lines = block.components(separatedBy: "\n")
        guard let tagsLineIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("tags:") }) else { return [] }

        let tagsLine = lines[tagsLineIndex].trimmingCharacters(in: .whitespaces)
        let afterColon = String(tagsLine.dropFirst("tags:".count)).trimmingCharacters(in: .whitespaces)

        if afterColon.hasPrefix("[") {
            let inner = afterColon.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            return inner.split(separator: ",").map { canonicalize(String($0)) }.filter { !$0.isEmpty }
        }

        if !afterColon.isEmpty {
            let value = canonicalize(afterColon)
            return value.isEmpty ? [] : [value]
        }

        var tags: [String] = []
        for line in lines[(tagsLineIndex + 1)...] {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("-") else { break }
            let value = canonicalize(String(trimmed.dropFirst()))
            if !value.isEmpty { tags.append(value) }
        }
        return tags
    }

    /// Every tag referenced in `content` (inline + frontmatter), canonicalized and
    /// deduplicated, in first-seen order.
    static func extractAllTags(from content: String) -> [String] {
        let combined = extractInlineTags(from: content) + extractFrontmatterTags(from: content)
        var seen = Set<String>()
        var result: [String] = []
        for name in combined where !name.isEmpty {
            if seen.insert(name).inserted { result.append(name) }
        }
        return result
    }

    /// App-level tag identity: case-folded and trimmed, since CloudKit disallows
    /// `.unique` — this is what dedupe (locally and on sync merge) keys off of.
    static func canonicalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "#\"'"))
            .lowercased()
    }

    private static func frontmatterBlock(in content: String) -> String? {
        let lines = content.components(separatedBy: "\n")
        guard let firstLine = lines.first, firstLine.trimmingCharacters(in: .whitespaces) == "---" else { return nil }
        guard let closingOffset = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else { return nil }
        return lines[1..<closingOffset].joined(separator: "\n")
    }

    /// The in-progress query text for an unclosed `#query` at the end of `content`, or `nil`
    /// if there's no active tag being typed. Same end-of-string heuristic as
    /// `WikilinkParser.activeQuery`.
    static func activeQuery(in content: String) -> String? {
        guard let hashRange = content.range(of: "#", options: .backwards) else { return nil }
        let afterHash = content[hashRange.upperBound...]
        guard !afterHash.contains(where: { $0.isWhitespace }) else { return nil }
        guard afterHash.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else { return nil }
        return String(afterHash)
    }

    /// Replaces the trailing in-progress `#query` (as found by `activeQuery`) with a
    /// completed `#tag ` tag. No-op if there's no active query.
    static func applying(tag: String, to content: String) -> String {
        guard let hashRange = content.range(of: "#", options: .backwards) else { return content }
        let afterHash = content[hashRange.upperBound...]
        guard !afterHash.contains(where: { $0.isWhitespace }),
              afterHash.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }) else { return content }
        return content.replacingCharacters(in: hashRange.lowerBound..<content.endIndex, with: "#\(tag) ")
    }

}
