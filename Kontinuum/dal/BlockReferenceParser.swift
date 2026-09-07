// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BlockReferenceParser.swift
//  Kontinuum
//

import Foundation

/// `((anchor))` extraction for block-reference indexing, plus the autocomplete heuristics for
/// the in-progress `((query` a user is typing. Sibling to `WikilinkParser` — same shape, one
/// level down (a `Block`'s anchor rather than a `Document`'s title).
///
/// Kept in sync with (but separate from) MarkdownG9's own block-reference-to-link rewrite in
/// `MDProcessor` — that one is about rendering, this one is about indexing/editing.
enum BlockReferenceParser {

    /// Excludes nested parens, matching `MDProcessor`'s own pattern exactly — a reference
    /// containing an inner `(...)` fails to match rather than capturing a truncated anchor.
    private static let blockReferencePattern = try! NSRegularExpression(pattern: #"\(\(([^()]+)\)\)"#)

    /// `!((anchor))` — Decision 5's live-transclusion embed. The `!` prefix mirrors Markdown's
    /// `![]()`-vs-`[]()` instinct; the `((anchor))` half still matches `blockReferencePattern`
    /// on its own, so `extractAnchors` finds an embed's anchor too without any change of its
    /// own — an embed is also a reference for backlink purposes.
    private static let embedPattern = try! NSRegularExpression(pattern: #"!\(\(([^()]+)\)\)"#)

    static func extractAnchors(from content: String) -> [String] {
        let nsContent = content as NSString
        let matches = blockReferencePattern.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
        return matches.map {
            nsContent.substring(with: $0.range(at: 1)).trimmingCharacters(in: .whitespaces)
        }
    }

    /// Anchors embedded via `!((anchor))` only — excludes a plain `((anchor))` link.
    static func extractEmbeds(from content: String) -> [String] {
        let nsContent = content as NSString
        let matches = embedPattern.matches(in: content, range: NSRange(location: 0, length: nsContent.length))
        return matches.map {
            nsContent.substring(with: $0.range(at: 1)).trimmingCharacters(in: .whitespaces)
        }
    }

    /// Whether `content` contains at least one `!((anchor))` embed — `DocumentPreviewView`'s
    /// signal to switch to the line-by-line render path, same role
    /// `EmbeddedSearchBlockParser.containsQueryBlock`/`AttachmentParser.containsAttachmentEmbed`
    /// already play for their own special block types.
    static func containsEmbed(_ content: String) -> Bool {
        embedPattern.firstMatch(in: content, range: NSRange(location: 0, length: (content as NSString).length)) != nil
    }

    /// The in-progress query text for an unclosed `((query` at the end of `content`, or `nil`
    /// if there's no active block reference being typed. Same end-of-string heuristic as
    /// `WikilinkParser.activeQuery`.
    static func activeQuery(in content: String) -> String? {
        guard let openRange = content.range(of: "((", options: .backwards) else { return nil }
        let afterOpen = content[openRange.upperBound...]
        guard !afterOpen.contains("))"), !afterOpen.contains("\n"), !afterOpen.contains("(") else { return nil }
        return String(afterOpen)
    }

    /// Replaces the trailing in-progress `((query` (as found by `activeQuery`) with a
    /// completed `((anchor)) ` reference. No-op if there's no active query.
    static func applying(anchor: String, to content: String) -> String {
        guard let openRange = content.range(of: "((", options: .backwards) else { return content }
        let afterOpen = content[openRange.upperBound...]
        guard !afterOpen.contains("))"), !afterOpen.contains("\n"), !afterOpen.contains("(") else { return content }
        return content.replacingCharacters(in: openRange.lowerBound..<content.endIndex, with: "((" + anchor + ")) ")
    }

    /// The in-progress query text for an unclosed `!((query` at the end of `content` — same
    /// heuristic as `activeQuery`, but only when the `((` is immediately preceded by `!`, so a
    /// plain `((query` in progress doesn't also register as an embed.
    static func activeEmbedQuery(in content: String) -> String? {
        guard let query = activeQuery(in: content),
              let openRange = content.range(of: "((", options: .backwards),
              content[..<openRange.lowerBound].hasSuffix("!")
        else { return nil }
        return query
    }

    /// Replaces the trailing in-progress `!((query` with a completed `!((anchor)) ` embed.
    /// No-op if there's no active embed query. Builds the literal string directly (not by
    /// prefixing `applying(anchor:)`'s output) so there's no risk of an extra closing paren
    /// sneaking in from string concatenation.
    static func applying(embedAnchor: String, to content: String) -> String {
        guard let openRange = content.range(of: "!((", options: .backwards) else { return content }
        let afterOpen = content[openRange.upperBound...]
        guard !afterOpen.contains("))"), !afterOpen.contains("\n"), !afterOpen.contains("(") else { return content }
        return content.replacingCharacters(in: openRange.lowerBound..<content.endIndex, with: "!((" + embedAnchor + ")) ")
    }

}
