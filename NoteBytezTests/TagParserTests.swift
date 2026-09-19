// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagParserTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

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

    // MARK: - Unicode correctness (G17)

    @Test func canonicalizeIsStableAcrossNFCAndNFDFormsOfTheSameText() {
        let precomposed = "café"           // é as a single precomposed codepoint (U+00E9)
        let decomposed = "cafe\u{0301}"    // e + combining acute accent (U+0065 U+0301)
        // Swift's `==` already treats these as canonically equivalent, so the meaningful check
        // is at the storage level: they differ in UTF-16 length until `canonicalize` normalizes
        // both to the same representation.
        #expect(precomposed.utf16.count != decomposed.utf16.count, "the two literals must actually differ at the storage level for this test to mean anything")
        #expect(TagParser.canonicalize(precomposed) == TagParser.canonicalize(decomposed))
        #expect(TagParser.canonicalize(decomposed).utf16.count == precomposed.utf16.count)
    }

    @Test func canonicalizeFoldsTurkishDottedCapitalIWithoutLeavingUppercaseLetters() {
        // "İ" (U+0130, dotted capital I) is the classic case-folding trap: under
        // `Locale.current` tailoring it folds differently on a Turkish device than anywhere
        // else. Canonicalization must use a locale-*invariant* rule instead, so it fully folds
        // regardless of which locale the test — or a real device — happens to run under.
        let canonical = TagParser.canonicalize("İstanbul")
        #expect(!canonical.contains(where: { $0.isUppercase }))
    }

    @Test func canonicalizeDoesNotMergeGermanSharpSWithDoubleS() {
        // "straße" and "STRASSE" are different spellings, not case variants of one another —
        // canonicalization must not accidentally collapse them into the same tag identity.
        #expect(TagParser.canonicalize("straße") != TagParser.canonicalize("STRASSE"))
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
