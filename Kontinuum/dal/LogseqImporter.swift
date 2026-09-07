// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LogseqImporter.swift
//  Kontinuum
//

import Foundation

/// Rewrites a Logseq page's raw Markdown into Kontinuum-native Markdown, pure/stateless like
/// `PropertyParser`/`TagParser` — no `ModelContext`. Logseq's own on-disk format is already
/// plain Markdown, but three things differ enough to need translation before Kontinuum's
/// existing block-splitting/task/search machinery can treat it as its own:
///
/// 1. **Tasks are keyword-prefixed, not GFM checkboxes.** `- TODO Buy milk` / `- DONE Buy milk`
///    become `- [ ] Buy milk` / `- [x] Buy milk` so `TaskParser`/`TaskDAL` recognize them for
///    free. Scoped to exactly `TODO`/`DONE`, per this phase's own plan wording — Logseq's fuller
///    workflow vocabulary (`DOING`/`NOW`/`LATER`/`WAITING`/`CANCELED`) is left as plain text
///    rather than guessed at.
/// 2. **Every bullet is its own block**, with no blank lines between siblings — Kontinuum's
///    `MarkdownBlockSplitter` splits on blank-line boundaries, so a raw Logseq page would
///    collapse into one giant `Block`. A blank line is inserted before each top-level (depth-0)
///    bullet only; a bullet's own nested children stay attached to it (no block-per-nesting-level
///    fidelity — a stated simplification, not a lossy one: the *content* and reading order are
///    fully preserved, only the parent/child block relationship isn't modeled as separate rows).
/// 3. **`{{query ...}}` blocks** map to Phase 5's ` ```query ``` ` embedded-search syntax for the
///    handful of simple, unambiguous shapes worth translating; anything else is flagged inline
///    (visible, not silently dropped) and recorded in `unsupportedQueries`, per Journey 9's
///    "flag, don't guess" requirement.
enum LogseqImporter {

    struct TransformResult {
        let content: String
        /// The original, untranslated `{{query ...}}` text for every occurrence this importer
        /// couldn't confidently map — one entry per occurrence, in document order.
        let unsupportedQueries: [String]
    }

    private enum BulletRewrite {
        case plain(String)
        case queryBlock(String)
        case unsupportedQuery(String)
    }

    private static let bulletPattern = try! NSRegularExpression(pattern: #"^(\s*)-\s+(.*)$"#)
    private static let queryLinePattern = try! NSRegularExpression(pattern: #"^\{\{query\s+(.*)\}\}$"#, options: [.caseInsensitive])
    private static let pageTagsPattern = try! NSRegularExpression(pattern: #"^page-tags\s+\"?([^")]+)\"?$"#, options: [.caseInsensitive])

    private static let taskKeywords: [(logseq: String, checkbox: String)] = [("TODO ", "[ ] "), ("DONE ", "[x] ")]

    // MARK: - Content transform

    static func transform(_ content: String) -> TransformResult {
        var outputLines: [String] = []
        var unsupportedQueries: [String] = []
        var isFirstBullet = true

        for line in content.components(separatedBy: "\n") {
            guard let (indent, text) = matchBullet(line) else {
                outputLines.append(line)
                continue
            }

            if indent.isEmpty {
                if !isFirstBullet { outputLines.append("") }
                isFirstBullet = false
            }

            switch rewriting(text) {
            case .plain(let rewrittenText):
                outputLines.append("\(indent)- \(rewrittenText)")
            case .queryBlock(let queryText):
                outputLines.append("```query")
                outputLines.append(queryText)
                outputLines.append("```")
            case .unsupportedQuery(let original):
                unsupportedQueries.append(original)
                outputLines.append("> ⚠️ Unsupported Logseq query — see the archived original vault: `\(original)`")
            }
        }

        return TransformResult(content: outputLines.joined(separator: "\n"), unsupportedQueries: unsupportedQueries)
    }

    // MARK: - Journal detection

    /// Logseq's default vault layout keeps every daily-journal page under a top-level
    /// `journals/` folder — matched case-insensitively since the folder name's casing isn't
    /// part of Logseq's own spec.
    static func isJournalFile(relativePath: String) -> Bool {
        relativePath.components(separatedBy: "/").dropLast().contains { $0.caseInsensitiveCompare("journals") == .orderedSame }
    }

    /// Logseq's classic default journal filename format is `yyyy_MM_dd.md`; newer versions
    /// default to `yyyy-MM-dd.md` — both are tried. `nil` for any other filename, e.g. a
    /// non-journal page that happens to live under a `journals/`-named folder.
    static func journalDate(forFileNamed fileName: String) -> Date? {
        let baseName = (fileName as NSString).deletingPathExtension
        return underscoreDateFormatter.date(from: baseName) ?? hyphenDateFormatter.date(from: baseName)
    }

    /// Deliberately no explicit `timeZone` — defaults to the system's current one, matching
    /// `JournalDAL.fetchOrCreate`'s own `Calendar.current.startOfDay(for:)` normalization. Using
    /// UTC here instead would shift the parsed date to the wrong local day for any negative-UTC-
    /// offset timezone.
    private static func makeDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }

    private static let underscoreDateFormatter = makeDateFormatter(format: "yyyy_MM_dd")
    private static let hyphenDateFormatter = makeDateFormatter(format: "yyyy-MM-dd")

    // MARK: - Line-level parsing

    private static func matchBullet(_ line: String) -> (indent: String, text: String)? {
        let nsLine = line as NSString
        guard let match = bulletPattern.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else { return nil }
        return (nsLine.substring(with: match.range(at: 1)), nsLine.substring(with: match.range(at: 2)))
    }

    private static func rewriting(_ text: String) -> BulletRewrite {
        var working = text
        var checkboxPrefix = ""
        for keyword in taskKeywords where working.hasPrefix(keyword.logseq) {
            checkboxPrefix = keyword.checkbox
            working = String(working.dropFirst(keyword.logseq.count))
            break
        }

        let trimmed = working.trimmingCharacters(in: .whitespaces)
        if let argument = queryArgument(in: trimmed) {
            if let mapped = mappedQueryText(for: argument) {
                return .queryBlock(mapped)
            }
            return .unsupportedQuery(trimmed)
        }

        return .plain(checkboxPrefix + working)
    }

    private static func queryArgument(in trimmedText: String) -> String? {
        let nsText = trimmedText as NSString
        guard let match = queryLinePattern.firstMatch(in: trimmedText, range: NSRange(location: 0, length: nsText.length)) else { return nil }
        return nsText.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
    }

    /// The only two Logseq query shapes translated: a bare quoted string (a plain-text search)
    /// and `(page-tags "Name")` (a tag search). Every other shape — boolean nesting, `property`/
    /// `between` filters, block references — returns `nil`, deliberately: guessing at a more
    /// elaborate query's intent risks silently showing the wrong notes, which Journey 9's own
    /// design implication calls out as worse than not migrating it at all.
    private static func mappedQueryText(for argument: String) -> String? {
        // `(page-tags "recipe")` arrives with its own enclosing parens still attached (Logseq's
        // query argument syntax) — stripped here, once, before pattern-matching against it.
        var working = argument
        if working.hasPrefix("("), working.hasSuffix(")") {
            working = String(working.dropFirst().dropLast()).trimmingCharacters(in: .whitespaces)
        }

        if working.hasPrefix("\""), working.hasSuffix("\""), working.count >= 2 {
            return String(working.dropFirst().dropLast())
        }

        let nsWorking = working as NSString
        if let match = pageTagsPattern.firstMatch(in: working, range: NSRange(location: 0, length: nsWorking.length)) {
            let tagName = nsWorking.substring(with: match.range(at: 1))
            return "#\(tagName)"
        }

        return nil
    }

}
