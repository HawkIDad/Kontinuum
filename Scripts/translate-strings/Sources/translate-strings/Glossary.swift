// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Glossary.swift
//  translate-strings
//

import Foundation

/// Parses `Docs/Localization/Glossary.md`'s "Terms" table (Phase 0.4 / G11) — a plain Markdown
/// pipe table, so the file stays human-editable without a special-purpose format.
struct Glossary {

    struct Term {
        let name: String
        let usageNote: String
        let defaultDirective: String
        /// Raw text of the "Per-language overrides" cell, e.g. `"zh-Hans: transliterate; ja: transliterate"`.
        let overridesCell: String
    }

    let terms: [Term]

    /// The directive (`translate` / `loanword` / `transliterate`) for `term` in `locale`,
    /// falling back to the term's default when no per-language override matches.
    func directive(for term: Term, locale: String) -> String {
        for clause in term.overridesCell.split(separator: ";") {
            let parts = clause.split(separator: ":", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            guard parts.count == 2, parts[0] == locale else { continue }
            return parts[1]
        }
        return term.defaultDirective
    }

    /// Every glossary term whose name appears (case-insensitively, whole-word) in `text` — the
    /// context handed to the translation model alongside each string.
    func hits(in text: String) -> [Term] {
        terms.filter { term in
            text.range(of: term.name, options: [.caseInsensitive]) != nil
        }
    }

    static func load(from url: URL) throws -> Glossary {
        let content = try String(contentsOf: url, encoding: .utf8)
        var terms: [Term] = []
        var inTermsTable = false

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("|") else {
                if trimmed.hasPrefix("## Terms") { inTermsTable = true }
                else if trimmed.hasPrefix("##"), inTermsTable { inTermsTable = false }
                continue
            }
            guard inTermsTable else { continue }

            let cells = trimmed
                .trimmingCharacters(in: CharacterSet(charactersIn: "|"))
                .components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            guard cells.count >= 4, cells[0] != "Term" else { continue }
            // The header's separator row ("---|---|...") — skip it.
            guard !cells[0].allSatisfy({ $0 == "-" }) else { continue }

            terms.append(Term(name: cells[0], usageNote: cells[1], defaultDirective: cells[2], overridesCell: cells[3]))
        }

        return Glossary(terms: terms)
    }

}
