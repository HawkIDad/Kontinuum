// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  WikilinkParserTests.swift
//  KontinuumTests
//

import Testing
@testable import Kontinuum

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
        #expect(WikilinkParser.fuzzyMatches("Project Kontinuum", query: "pkon"))
        #expect(!WikilinkParser.fuzzyMatches("Project Kontinuum", query: "xyz"))
    }

    @Test func fuzzyMatchesEmptyQueryMatchesEverything() {
        #expect(WikilinkParser.fuzzyMatches("Anything", query: ""))
    }

}
