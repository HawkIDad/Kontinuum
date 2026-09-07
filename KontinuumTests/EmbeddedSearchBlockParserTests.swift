// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  EmbeddedSearchBlockParserTests.swift
//  KontinuumTests
//

import Testing
@testable import Kontinuum

struct EmbeddedSearchBlockParserTests {

    @Test func parseReturnsAllPlainLinesWhenThereIsNoQueryBlock() {
        let content = "Line one.\nLine two."
        let lines = EmbeddedSearchBlockParser.parse(content)
        #expect(lines.count == 2)
        #expect(lines[0] == .plain("Line one."))
        #expect(lines[1] == .plain("Line two."))
    }

    @Test func parseCollapsesAFencedQueryBlockIntoOneQueryEntry() {
        let content = "Before.\n```query\n#character AND #act2\n```\nAfter."
        let lines = EmbeddedSearchBlockParser.parse(content)

        #expect(lines.count == 3)
        #expect(lines[0] == .plain("Before."))
        #expect(lines[1] == .query("#character AND #act2"))
        #expect(lines[2] == .plain("After."))
    }

    @Test func parseJoinsAMultiLineQueryBlockWithNewlines() {
        let content = "```query\n#character\nAND #act2\n```"
        let lines = EmbeddedSearchBlockParser.parse(content)

        #expect(lines == [.query("#character\nAND #act2")])
    }

    @Test func parseIsCaseInsensitiveForTheFenceOpener() {
        let content = "```QUERY\n#roadmap\n```"
        #expect(EmbeddedSearchBlockParser.parse(content) == [.query("#roadmap")])
    }

    @Test func parseHandlesAnUnterminatedFenceLeniently() {
        let content = "```query\n#roadmap"
        #expect(EmbeddedSearchBlockParser.parse(content) == [.query("#roadmap")])
    }

    @Test func parseHandlesAnEmptyQueryBlock() {
        let content = "```query\n```"
        #expect(EmbeddedSearchBlockParser.parse(content) == [.query("")])
    }

    @Test func containsQueryBlockIsTrueOnlyWhenAFenceIsPresent() {
        #expect(EmbeddedSearchBlockParser.containsQueryBlock("```query\n#a\n```"))
        #expect(!EmbeddedSearchBlockParser.containsQueryBlock("Just plain text."))
        #expect(!EmbeddedSearchBlockParser.containsQueryBlock("```swift\nlet x = 1\n```"))
    }

}
