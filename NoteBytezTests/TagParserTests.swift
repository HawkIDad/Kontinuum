// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagParserTests.swift
//  KontinuumTests
//

import Testing
@testable import Kontinuum

struct TagParserTests {

    @Test func extractInlineTagsFindsEveryTag() {
        let content = "Filed under #roadmap and #mvp today."
        #expect(TagParser.extractInlineTags(from: content) == ["roadmap", "mvp"])
    }

    @Test func extractInlineTagsReturnsEmptyForPlainText() {
        #expect(TagParser.extractInlineTags(from: "No tags here.").isEmpty)
    }

    @Test func extractInlineTagsCanonicalizesCase() {
        #expect(TagParser.extractInlineTags(from: "#Roadmap") == ["roadmap"])
    }

    @Test func extractInlineTagsIgnoresAHeading() {
        #expect(TagParser.extractInlineTags(from: "# Heading").isEmpty)
    }

    @Test func extractInlineTagsIgnoresANestedHeadingMarker() {
        #expect(TagParser.extractInlineTags(from: "## Subheading").isEmpty)
    }

    @Test func extractInlineTagsIgnoresAMidWordHash() {
        #expect(TagParser.extractInlineTags(from: "C#sharp").isEmpty)
    }

    @Test func extractFrontmatterTagsParsesFlowList() {
        let content = "---\ntags: [Roadmap, MVP]\n---\nBody text."
        #expect(TagParser.extractFrontmatterTags(from: content) == ["roadmap", "mvp"])
    }

    @Test func extractFrontmatterTagsParsesBlockList() {
        let content = "---\ntitle: Notes\ntags:\n  - Roadmap\n  - MVP\n---\nBody text."
        #expect(TagParser.extractFrontmatterTags(from: content) == ["roadmap", "mvp"])
    }

    @Test func extractFrontmatterTagsParsesSingleInlineValue() {
        let content = "---\ntags: Roadmap\n---\nBody text."
        #expect(TagParser.extractFrontmatterTags(from: content) == ["roadmap"])
    }

    @Test func extractFrontmatterTagsReturnsEmptyWithNoFrontmatter() {
        #expect(TagParser.extractFrontmatterTags(from: "Just body text.").isEmpty)
    }

    @Test func extractAllTagsDedupesInlineAndFrontmatter() {
        let content = "---\ntags: [Roadmap]\n---\nSee #roadmap and #mvp."
        #expect(TagParser.extractAllTags(from: content) == ["roadmap", "mvp"])
    }

    @Test func canonicalizeCaseFoldsAndTrims() {
        #expect(TagParser.canonicalize("  #Roadmap  ") == "roadmap")
    }

    @Test func activeQueryDetectsUnclosedTagAtEndOfContent() {
        #expect(TagParser.activeQuery(in: "Type #road") == "road")
    }

    @Test func activeQueryIsNilAfterWhitespace() {
        #expect(TagParser.activeQuery(in: "Type #roadmap done") == nil)
    }

    @Test func activeQueryIsNilWithNoHash() {
        #expect(TagParser.activeQuery(in: "Just plain text") == nil)
    }

    @Test func applyingInsertsCompletedTagOverActiveQuery() {
        let result = TagParser.applying(tag: "roadmap", to: "See #road")
        #expect(result == "See #roadmap ")
    }

    @Test func applyingIsNoOpWhenNoActiveQuery() {
        let result = TagParser.applying(tag: "roadmap", to: "Nothing in progress")
        #expect(result == "Nothing in progress")
    }

}
