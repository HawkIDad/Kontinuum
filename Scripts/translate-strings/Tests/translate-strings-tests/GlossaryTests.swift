// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GlossaryTests.swift
//  translate-strings-tests
//

import Testing
import Foundation
@testable import translate_strings

struct GlossaryTests {

    private func writeGlossary(_ markdown: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".md")
        try markdown.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private let sampleMarkdown = """
    # Product Term Glossary

    ## Directives

    | Directive | Meaning |
    |---|---|
    | `translate` | Render in the target language. |

    ## Terms

    | Term | Usage note | Default Directive | Per-language overrides |
    |---|---|---|---|
    | Backlink | A link to the current note. | loanword | zh-Hans: transliterate; ja: transliterate |
    | Notebook | A grouping of notes. | translate | |

    ## Adding a new term

    Some trailing prose that must not be parsed as a row.
    """

    @Test func loadParsesEveryTermRow() throws {
        let glossary = try Glossary.load(from: writeGlossary(sampleMarkdown))
        #expect(glossary.terms.map { $0.name } == ["Backlink", "Notebook"])
    }

    @Test func directiveFallsBackToDefaultWhenNoOverrideMatches() throws {
        let glossary = try Glossary.load(from: writeGlossary(sampleMarkdown))
        let backlink = try #require(glossary.terms.first { $0.name == "Backlink" })
        #expect(glossary.directive(for: backlink, locale: "fr") == "loanword")
    }

    @Test func directiveUsesThePerLanguageOverrideWhenPresent() throws {
        let glossary = try Glossary.load(from: writeGlossary(sampleMarkdown))
        let backlink = try #require(glossary.terms.first { $0.name == "Backlink" })
        #expect(glossary.directive(for: backlink, locale: "zh-Hans") == "transliterate")
    }

    @Test func hitsFindsTermsMentionedInAString() throws {
        let glossary = try Glossary.load(from: writeGlossary(sampleMarkdown))
        let hits = glossary.hits(in: "This Notebook has 3 Backlinks.")
        #expect(Set(hits.map { $0.name }) == ["Backlink", "Notebook"])
    }

    @Test func hitsReturnsEmptyForUnrelatedText() throws {
        let glossary = try Glossary.load(from: writeGlossary(sampleMarkdown))
        #expect(glossary.hits(in: "Settings").isEmpty)
    }

}
