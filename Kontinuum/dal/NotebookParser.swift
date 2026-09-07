// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookParser.swift
//  Kontinuum
//

import Foundation

/// YAML frontmatter `notebooks:` extraction, for import round-trip. Unlike `TagParser`,
/// values are kept exactly as written (no case-folding) — Notebook membership matches by
/// exact name, per NoteBytez-ReleaseFeatures.md's Decisions Log.
enum NotebookParser {

    /// Parses the `notebooks:` key out of a leading `---`-delimited YAML frontmatter block, in
    /// any of its three common forms: flow list (`notebooks: [a, b]`), block list
    /// (`notebooks:` followed by `- a` / `- b` lines), or a single inline value
    /// (`notebooks: a`). Not a general YAML parser — only what `notebooks:` needs, mirroring
    /// `TagParser.extractFrontmatterTags`.
    static func extractFrontmatterNotebooks(from content: String) -> [String] {
        guard let block = frontmatterBlock(in: content) else { return [] }
        let lines = block.components(separatedBy: "\n")
        guard let notebooksLineIndex = lines.firstIndex(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("notebooks:") }) else { return [] }

        let notebooksLine = lines[notebooksLineIndex].trimmingCharacters(in: .whitespaces)
        let afterColon = String(notebooksLine.dropFirst("notebooks:".count)).trimmingCharacters(in: .whitespaces)

        if afterColon.hasPrefix("[") {
            let inner = afterColon.trimmingCharacters(in: CharacterSet(charactersIn: "[]"))
            return inner.split(separator: ",").map(unquote).filter { !$0.isEmpty }
        }

        if !afterColon.isEmpty {
            let value = unquote(Substring(afterColon))
            return value.isEmpty ? [] : [value]
        }

        var notebooks: [String] = []
        for line in lines[(notebooksLineIndex + 1)...] {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("-") else { break }
            let value = unquote(trimmed.dropFirst())
            if !value.isEmpty { notebooks.append(value) }
        }
        return notebooks
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

}
