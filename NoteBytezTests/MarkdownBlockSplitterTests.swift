// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MarkdownBlockSplitterTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

struct MarkdownBlockSplitterTests {

    @Test func splitsOnBlankLines() {
        let chunks = MarkdownBlockSplitter.split("First paragraph.\n\nSecond paragraph.")
        #expect(chunks == ["First paragraph.", "Second paragraph."])
    }

    @Test func doesNotSplitInsideFencedCodeBlock() {
        let markdown = "```\nlet x = 1\n\nlet y = 2\n```"
        let chunks = MarkdownBlockSplitter.split(markdown)
        #expect(chunks == [markdown])
    }

    @Test func collapsesMultipleBlankLinesToOneBoundary() {
        let chunks = MarkdownBlockSplitter.split("First.\n\n\n\nSecond.")
        #expect(chunks == ["First.", "Second."])
    }

    @Test func trimsLeadingAndTrailingWhitespacePerChunk() {
        let chunks = MarkdownBlockSplitter.split("\n\n  First.  \n\n")
        #expect(chunks == ["First."])
    }

    @Test func joinReconstructsBlankLineSeparatedMarkdown() {
        let original = "# Heading\n\nA paragraph.\n\n- item one\n- item two"
        let chunks = MarkdownBlockSplitter.split(original)
        #expect(MarkdownBlockSplitter.join(chunks) == original)
    }

    @Test func roundTripIsStableAcrossRepeatedSplitJoin() {
        let original = "# Title\n\nBody text here.\n\n```\nlet x = 1\n```\n\n> A quote"
        let firstPass = MarkdownBlockSplitter.join(MarkdownBlockSplitter.split(original))
        let secondPass = MarkdownBlockSplitter.join(MarkdownBlockSplitter.split(firstPass))
        #expect(firstPass == original)
        #expect(secondPass == firstPass)
    }

    // MARK: - split(withHeadingContext:)

    @Test func splitWithHeadingContextPairsEachChunkWithItsEnclosingPath() {
        let markdown = "# A\n\npara1\n\n## B\n\npara2\n\n# C\n\npara3"
        let result = MarkdownBlockSplitter.split(withHeadingContext: markdown)

        #expect(result.count == 6)
        #expect(result[0].content == "# A" && result[0].headingPath == [])
        #expect(result[1].content == "para1" && result[1].headingPath == ["A"])
        #expect(result[2].content == "## B" && result[2].headingPath == ["A"])
        #expect(result[3].content == "para2" && result[3].headingPath == ["A", "B"])
        #expect(result[4].content == "# C" && result[4].headingPath == [])
        #expect(result[5].content == "para3" && result[5].headingPath == ["C"])
    }

    @Test func splitWithHeadingContextIgnoresHeadingSyntaxInsideAFence() {
        let markdown = "# Real Heading\n\npara\n\n```\n# not a heading\n```"
        let result = MarkdownBlockSplitter.split(withHeadingContext: markdown)

        #expect(result.map(\.content) == ["# Real Heading", "para", "```\n# not a heading\n```"])
        #expect(result[2].headingPath == ["Real Heading"])
    }

    @Test func splitWithHeadingContextLevelJumpDoesNotPushAPhantomMiddleLevel() {
        let markdown = "# A\n\n### B\n\npara"
        let result = MarkdownBlockSplitter.split(withHeadingContext: markdown)

        #expect(result.map(\.content) == ["# A", "### B", "para"])
        #expect(result[2].headingPath == ["A", "B"])
    }

    @Test func splitWithHeadingContextContentBeforeAnyHeadingHasEmptyPath() {
        let markdown = "para0\n\n# A\n\npara1"
        let result = MarkdownBlockSplitter.split(withHeadingContext: markdown)

        #expect(result[0].content == "para0" && result[0].headingPath == [])
        #expect(result[2].headingPath == ["A"])
    }

}
