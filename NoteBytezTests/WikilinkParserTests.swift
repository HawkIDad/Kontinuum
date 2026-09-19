// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  WikilinkParserTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

struct WikilinkParserTests {

    @Test func extractTitlesFindsEveryWikilink() {
        let content = "See [[Note One]] and also [[Note Two]]."
        #expect(WikilinkParser.extractTitles(from: content) == ["Note One", "Note Two"])
    }

    @Test func extractTitlesReturnsEmptyForPlainText() {
        #expect(WikilinkParser.extractTitles(from: "No links here.").isEmpty)
    }

    @Test func extractTitlesStripsTheHeadingSuffixFromASectionLink() {
        #expect(WikilinkParser.extractTitles(from: "See [[Note One#Setup]] for context.") == ["Note One"])
    }

    // MARK: - parseTarget

    @Test func parseTargetSplitsTitleAndHeadingOnTheFirstHash() {
        let target = WikilinkParser.parseTarget("A#B")
        #expect(target.title == "A")
        #expect(target.heading == "B")
    }

    @Test func parseTargetHasNoHeadingWhenThereIsNoHash() {
        let target = WikilinkParser.parseTarget("A")
        #expect(target.title == "A")
        #expect(target.heading == nil)
    }

    @Test func renamingWikilinksRewritesMatchingTitleCaseInsensitively() {
        let content = "Refer to [[old title]] for background."
        let renamed = WikilinkParser.renamingWikilinks(from: "Old Title", to: "New Title", in: content)
        #expect(renamed == "Refer to [[New Title]] for background.")
    }

    @Test func renamingWikilinksLeavesOtherWikilinksUntouched() {
        let content = "[[Keep This]] and [[Old Title]]"
        let renamed = WikilinkParser.renamingWikilinks(from: "Old Title", to: "New Title", in: content)
        #expect(renamed == "[[Keep This]] and [[New Title]]")
    }

    @Test func renamingWikilinksHandlesRegexSpecialCharactersInOldTitle() {
        let content = "See [[C++ (draft)]] for the plan."
        let renamed = WikilinkParser.renamingWikilinks(from: "C++ (draft)", to: "C++ Final", in: content)
        #expect(renamed == "See [[C++ Final]] for the plan.")
    }

    @Test func renamingWikilinksPreservesTheHeadingSuffixOfASectionLink() {
        let renamed = WikilinkParser.renamingWikilinks(from: "A", to: "C", in: "[[A#B]]")
        #expect(renamed == "[[C#B]]")
    }

    @Test func activeQueryDetectsUnclosedWikilinkAtEndOfContent() {
        #expect(WikilinkParser.activeQuery(in: "Type [[Some") == "Some")
    }

    @Test func activeQueryIsNilWhenWikilinkIsClosed() {
        #expect(WikilinkParser.activeQuery(in: "Type [[Some]] done") == nil)
    }

    @Test func activeQueryIsNilWithNoOpenBrackets() {
        #expect(WikilinkParser.activeQuery(in: "Just plain text") == nil)
    }

    @Test func activeQueryIsNilAcrossANewline() {
        #expect(WikilinkParser.activeQuery(in: "Type [[Some\nMore text") == nil)
    }

    @Test func applyingInsertsCompletedWikilinkOverActiveQuery() {
        let result = WikilinkParser.applying(title: "My Note", to: "See [[My N")
        #expect(result == "See [[My Note]] ")
    }

    @Test func applyingIsNoOpWhenNoActiveQuery() {
        let result = WikilinkParser.applying(title: "My Note", to: "Nothing in progress")
        #expect(result == "Nothing in progress")
    }

    @Test func fuzzyMatchesSubsequenceRegardlessOfCase() {
        #expect(WikilinkParser.fuzzyMatches("Project NoteBytez", query: "pnot"))
        #expect(!WikilinkParser.fuzzyMatches("Project NoteBytez", query: "xyz"))
    }

    @Test func fuzzyMatchesEmptyQueryMatchesEverything() {
        #expect(WikilinkParser.fuzzyMatches("Anything", query: ""))
    }

    /// G17: an NFD-decomposed candidate and an NFC-precomposed query for the same visible text
    /// must still match — normalization happens before the character-by-character comparison.
    @Test func fuzzyMatchesAcrossNFCAndNFDFormsOfTheSameCharacter() {
        let decomposedCandidate = "cafe\u{0301} notes" // NFD é
        #expect(WikilinkParser.fuzzyMatches(decomposedCandidate, query: "café")) // NFC é
    }

    /// G17: a plain-ASCII query fuzzy-matches an accented candidate.
    @Test func fuzzyMatchesIsDiacriticInsensitive() {
        #expect(WikilinkParser.fuzzyMatches("Café Notes", query: "cafe"))
    }

}
