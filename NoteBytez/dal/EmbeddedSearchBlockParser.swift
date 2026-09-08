// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  EmbeddedSearchBlockParser.swift
//  NoteBytez
//

import Foundation

/// A fenced ` ```query ... ``` ` block embeds a live search query inline in a note, per
/// NoteBytez-ReleaseFeatures.md's "Embedded search-result blocks" — resolved at render/preview
/// time (see `DocumentPreviewView`), never persisted as static content. The fence itself is
/// ordinary Markdown fenced-code-block syntax, so a document containing one still round-trips
/// through export/import and reads sensibly (as a plain code block) in Obsidian/Logseq or any
/// other Markdown tool.
enum EmbeddedSearchBlockParser {

    /// `nonisolated`: pure line-classification data with no UI/shared-state ties, opted out of
    /// this target's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — otherwise its `Equatable`
    /// conformance is itself MainActor-isolated, which test assertions (`#expect(a == b)`,
    /// generated as nonisolated code) can't call into (a warning today, a Swift 6 error).
    nonisolated enum ContentLine: Equatable {
        case plain(String)
        case query(String)
    }

    private static let fenceOpen = "```query"
    private static let fenceClose = "```"

    /// Splits `content` into an ordered sequence of plain lines and embedded query blocks —
    /// each fenced block collapses to one `.query` entry carrying its (trimmed, joined) inner
    /// text, however many lines it spanned. An unterminated fence (no closing ` ``` ` before
    /// the document ends) still collapses to a `.query` entry from whatever follows the opener,
    /// rather than being treated as plain text — the same "don't punish a mid-edit document"
    /// leniency `TagParser`'s frontmatter block-finder already applies elsewhere.
    static func parse(_ content: String) -> [ContentLine] {
        let lines = content.components(separatedBy: "\n")
        var result: [ContentLine] = []
        var index = 0

        while index < lines.count {
            guard lines[index].trimmingCharacters(in: .whitespaces).caseInsensitiveCompare(fenceOpen) == .orderedSame else {
                result.append(.plain(lines[index]))
                index += 1
                continue
            }

            var inner: [String] = []
            var lookahead = index + 1
            while lookahead < lines.count, lines[lookahead].trimmingCharacters(in: .whitespaces) != fenceClose {
                inner.append(lines[lookahead])
                lookahead += 1
            }
            result.append(.query(inner.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
            index = lookahead < lines.count ? lookahead + 1 : lookahead
        }

        return result
    }

    static func containsQueryBlock(_ content: String) -> Bool {
        parse(content).contains { if case .query = $0 { return true }; return false }
    }

}
