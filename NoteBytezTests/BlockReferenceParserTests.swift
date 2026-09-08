// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BlockReferenceParserTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

struct BlockReferenceParserTests {

    @Test func extractAnchorsFindsEveryReference() {
        let content = "See ((review-pr)) and also ((follow-up))."
        #expect(BlockReferenceParser.extractAnchors(from: content) == ["review-pr", "follow-up"])
    }

    @Test func extractAnchorsReturnsEmptyForPlainText() {
        #expect(BlockReferenceParser.extractAnchors(from: "No references here.").isEmpty)
    }

    @Test func extractAnchorsIgnoresASingleParenthetical() {
        #expect(BlockReferenceParser.extractAnchors(from: "Filed under (informal) notes.").isEmpty)
    }

    @Test func extractAnchorsIgnoresAnAnchorBrokenUpByANestedParenthetical() {
        #expect(BlockReferenceParser.extractAnchors(from: "((a (b) c))").isEmpty)
    }

    @Test func activeQueryDetectsUnclosedReferenceAtEndOfContent() {
        #expect(BlockReferenceParser.activeQuery(in: "Type ((some") == "some")
    }

    @Test func activeQueryIsNilWhenReferenceIsClosed() {
        #expect(BlockReferenceParser.activeQuery(in: "Type ((some)) done") == nil)
    }

    @Test func activeQueryIsNilWithNoOpenParens() {
        #expect(BlockReferenceParser.activeQuery(in: "Just plain text") == nil)
    }

    @Test func activeQueryIsNilAcrossANewline() {
        #expect(BlockReferenceParser.activeQuery(in: "Type ((some\nMore text") == nil)
    }

    @Test func applyingInsertsCompletedReferenceOverActiveQuery() {
        let result = BlockReferenceParser.applying(anchor: "review-pr", to: "See ((rev")
        #expect(result == "See ((review-pr)) ")
    }

    @Test func applyingIsNoOpWhenNoActiveQuery() {
        let result = BlockReferenceParser.applying(anchor: "review-pr", to: "Nothing in progress")
        #expect(result == "Nothing in progress")
    }

    // MARK: - Live transclusion (Decision 5): !((anchor))

    @Test func extractEmbedsFindsAnchorsFromTheBangPrefixedForm() {
        #expect(BlockReferenceParser.extractEmbeds(from: "See !((review-pr)) for the summary.") == ["review-pr"])
    }

    @Test func extractEmbedsDoesNotMatchAPlainReference() {
        #expect(BlockReferenceParser.extractEmbeds(from: "See ((review-pr)) for the summary.").isEmpty)
    }

    @Test func extractAnchorsStillFindsAnEmbedsAnchorToo() {
        // A `!((a))` embed is also a reference for backlink purposes.
        #expect(BlockReferenceParser.extractAnchors(from: "!((review-pr))") == ["review-pr"])
    }

    @Test func applyingEmbedAnchorInsertsTheBangPrefixedFormWithExactlyTwoClosingParens() {
        let result = BlockReferenceParser.applying(embedAnchor: "review-pr", to: "See !((rev")
        #expect(result == "See !((review-pr)) ")
        #expect(!result.contains(")))"))
    }

    @Test func activeEmbedQueryDetectsAnUnclosedBangPrefixedReference() {
        #expect(BlockReferenceParser.activeEmbedQuery(in: "Type !((some") == "some")
    }

    @Test func activeEmbedQueryIsNilForAPlainUnclosedReference() {
        #expect(BlockReferenceParser.activeEmbedQuery(in: "Type ((some") == nil)
    }

    @Test func activeEmbedQueryIsNilWhenReferenceIsClosed() {
        #expect(BlockReferenceParser.activeEmbedQuery(in: "Type !((some)) done") == nil)
    }

    @Test func containsEmbedIsTrueOnlyWhenABangPrefixedReferenceIsPresent() {
        #expect(BlockReferenceParser.containsEmbed("See !((anchor)) here."))
        #expect(!BlockReferenceParser.containsEmbed("See ((anchor)) here."))
        #expect(!BlockReferenceParser.containsEmbed("Plain text."))
    }

}
