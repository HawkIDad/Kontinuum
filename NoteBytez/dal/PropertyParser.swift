// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PropertyParser.swift
//  Kontinuum
//

import Foundation

/// YAML frontmatter typed-Property extraction and round-trip writing. Unlike `Tag`, a
/// Property has no inline-in-body syntax — frontmatter is its only representation, per
/// NoteBytez-ReleaseFeatures.md's Version 1 section ("Properties... stored as frontmatter").
/// Mirrors `TagParser`/`NotebookParser`'s frontmatter-block handling.
enum PropertyParser {

    /// Frontmatter keys already claimed by another feature — never read back as a Property,
    /// so a document's `tags:`/`notebooks:` lines aren't double-indexed as typed fields too.
    static let reservedKeys: Set<String> = ["tags", "notebooks"]

    /// Known limitation of inferring a type from the value string rather than storing one
    /// explicitly: an empty `.date`/`.number`/`.checkbox` value (e.g. a Note Template field —
    /// Phase 3 — applied with a blank default) has no textual signal to infer from and reads
    /// back as `.text` until a real value is entered. Accepted rather than worked around, since
    /// the alternative is storing an explicit type independent of the value, which the rest of
    /// this reconcile-from-content design deliberately avoids.

    private static let dateValuePattern = try! NSRegularExpression(pattern: #"^\d{4}-\d{2}-\d{2}$"#)

    /// Every non-reserved `key: value` line in `content`'s frontmatter block, typed by
    /// inference (see `inferredType(for:)`). Order matches the frontmatter block itself.
    static func extractFrontmatterProperties(from content: String) -> [(key: String, value: String, valueType: PropertyValueType)] {
        guard let block = frontmatterBlock(in: content) else { return [] }
        let lines = block.components(separatedBy: "\n")

        var results: [(key: String, value: String, valueType: PropertyValueType)] = []
        var index = 0
        while index < lines.count {
            let line = lines[index]
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard let colonRange = trimmed.range(of: ":"), !trimmed.hasPrefix("-") else { index += 1; continue }

            let key = String(trimmed[trimmed.startIndex..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            guard !key.isEmpty, !reservedKeys.contains(key.lowercased()) else { index += 1; continue }

            let afterColon = String(trimmed[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)

            if afterColon.hasPrefix("[") {
                let inner = afterColon.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
                let items = inner.split(separator: ",").map(unquote).filter { !$0.isEmpty }
                results.append((key, items.joined(separator: "; "), .list))
                index += 1
                continue
            }

            if afterColon.isEmpty {
                // Possible block list: subsequent `- item` lines indented under this key.
                var items: [String] = []
                var lookahead = index + 1
                while lookahead < lines.count {
                    let nextTrimmed = lines[lookahead].trimmingCharacters(in: .whitespaces)
                    guard nextTrimmed.hasPrefix("-") else { break }
                    let value = unquote(nextTrimmed.dropFirst())
                    if !value.isEmpty { items.append(value) }
                    lookahead += 1
                }
                if !items.isEmpty {
                    results.append((key, items.joined(separator: "; "), .list))
                    index = lookahead
                    continue
                }
                index += 1
                continue
            }

            // `afterColon` (pre-unquote) is known non-empty here — an explicit `key: ""` is a
            // deliberate empty value (e.g. an unfilled Note Template field, Phase 3), not the
            // "nothing follows the colon" ambiguity the block-list branch above already handles.
            // Only the *raw* emptiness should have skipped this key, so an empty string after
            // unquoting is still a real, indexed Property value.
            let value = unquote(Substring(afterColon))
            results.append((key, value, inferredType(for: value)))
            index += 1
        }
        return results
    }

    /// Sets (or replaces) a single frontmatter `key: value` line, creating the frontmatter
    /// block if `content` doesn't have one yet. Every other line — including other
    /// Properties, `tags:`, `notebooks:` — is left untouched, mirroring `ExportDAL`'s
    /// "don't rewrite what you don't own" approach to a user's frontmatter.
    static func applying(key: String, value: String, valueType: PropertyValueType, to content: String) -> String {
        let (frontmatterLines, body) = splitFrontmatter(content)
        let updatedLines = frontmatterLines.filter { !isLine(for: key, in: $0) } + [line(key: key, value: value, valueType: valueType)]
        return rebuild(frontmatterLines: updatedLines, body: body)
    }

    /// Removes a Property's frontmatter line entirely — the DAL-level "remove a document's
    /// property value" operation reads through to this, keeping content the single source of
    /// truth rather than a second, disconnected deletion path.
    static func removingProperty(key: String, from content: String) -> String {
        let (frontmatterLines, body) = splitFrontmatter(content)
        let updatedLines = frontmatterLines.filter { !isLine(for: key, in: $0) }
        return rebuild(frontmatterLines: updatedLines, body: body)
    }

    private static func isLine(for key: String, in rawLine: String) -> Bool {
        rawLine.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("\(key.lowercased()):")
    }

    private static func line(key: String, value: String, valueType: PropertyValueType) -> String {
        switch valueType {
        case .list:
            let items = value.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return "\(key): [" + items.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
        case .checkbox, .number, .date:
            return "\(key): \(value)"
        case .text:
            return "\(key): \"\(value)\""
        }
    }

    private static func rebuild(frontmatterLines: [String], body: String) -> String {
        guard !frontmatterLines.isEmpty else { return body }
        return "---\n" + frontmatterLines.joined(separator: "\n") + "\n---\n\n" + body
    }

    /// checkbox > date > number > text, in that priority — a bare "true"/"false" or a
    /// `yyyy-MM-dd` string should never fall through to being read as freeform text.
    private static func inferredType(for value: String) -> PropertyValueType {
        if value.caseInsensitiveCompare("true") == .orderedSame || value.caseInsensitiveCompare("false") == .orderedSame {
            return .checkbox
        }
        if dateValuePattern.firstMatch(in: value, range: NSRange(value.startIndex..., in: value)) != nil {
            return .date
        }
        if Double(value) != nil {
            return .number
        }
        return .text
    }

    private nonisolated static func unquote(_ raw: Substring) -> String {
        raw.trimmingCharacters(in: .whitespaces).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private static func frontmatterBlock(in content: String) -> String? {
        let lines = content.components(separatedBy: "\n")
        guard let firstLine = lines.first, firstLine.trimmingCharacters(in: .whitespaces) == "---" else { return nil }
        guard let closingOffset = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else { return nil }
        return lines[1..<closingOffset].joined(separator: "\n")
    }

    private static func splitFrontmatter(_ content: String) -> (frontmatterLines: [String], body: String) {
        let lines = content.components(separatedBy: "\n")
        guard let firstLine = lines.first, firstLine.trimmingCharacters(in: .whitespaces) == "---",
              let closingOffset = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else {
            return ([], content)
        }
        let frontmatterLines = Array(lines[1..<closingOffset])
        let body = lines[(closingOffset + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (frontmatterLines, body)
    }

}
