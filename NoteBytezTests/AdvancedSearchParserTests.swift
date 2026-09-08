// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AdvancedSearchParserTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

struct AdvancedSearchParserTests {

    // MARK: - Parsing shape

    @Test func parsesASingleTagTerm() {
        #expect(AdvancedSearchParser.parse("#character") == .tag("character"))
    }

    @Test func parsesASingleBareWord() {
        #expect(AdvancedSearchParser.parse("roadmap") == .text("roadmap"))
    }

    @Test func parsesAQuotedPhrase() {
        #expect(AdvancedSearchParser.parse(#""exact phrase""#) == .text("exact phrase"))
    }

    @Test func parsesARegexTerm() {
        #expect(AdvancedSearchParser.parse("/^Chapter [0-9]+/") == .regex("^Chapter [0-9]+"))
    }

    @Test func parsesExplicitAnd() {
        #expect(AdvancedSearchParser.parse("#character AND #act2") == .and(.tag("character"), .tag("act2")))
    }

    @Test func parsesImplicitAndBetweenAdjacentTerms() {
        #expect(AdvancedSearchParser.parse("#character #act2") == .and(.tag("character"), .tag("act2")))
    }

    @Test func parsesOr() {
        #expect(AdvancedSearchParser.parse("#character OR #villain") == .or(.tag("character"), .tag("villain")))
    }

    @Test func parsesNot() {
        #expect(AdvancedSearchParser.parse("NOT #resolved") == .not(.tag("resolved")))
    }

    @Test func parsesTheReleaseFeaturesExampleQueryWithCorrectPrecedence() {
        // #character AND #act2 NOT #resolved -> (character AND act2) AND (NOT resolved)
        let expected = AdvancedSearchParser.Node.and(
            .and(.tag("character"), .tag("act2")),
            .not(.tag("resolved"))
        )
        #expect(AdvancedSearchParser.parse("#character AND #act2 NOT #resolved") == expected)
    }

    @Test func orBindsLooserThanAnd() {
        // a AND b OR c -> (a AND b) OR c
        let expected = AdvancedSearchParser.Node.or(.and(.text("a"), .text("b")), .text("c"))
        #expect(AdvancedSearchParser.parse("a AND b OR c") == expected)
    }

    @Test func parenthesesOverridePrecedence() {
        // a AND (b OR c)
        let expected = AdvancedSearchParser.Node.and(.text("a"), .or(.text("b"), .text("c")))
        #expect(AdvancedSearchParser.parse("a AND (b OR c)") == expected)
    }

    @Test func parseIsCaseInsensitiveForOperatorKeywords() {
        #expect(AdvancedSearchParser.parse("#a and #b") == .and(.tag("a"), .tag("b")))
        #expect(AdvancedSearchParser.parse("#a or #b") == .or(.tag("a"), .tag("b")))
        #expect(AdvancedSearchParser.parse("not #a") == .not(.tag("a")))
    }

    @Test func parseReturnsNilForBlankQuery() {
        #expect(AdvancedSearchParser.parse("   ") == nil)
    }

    @Test func parseReturnsNilForUnbalancedParentheses() {
        #expect(AdvancedSearchParser.parse("(#a AND #b") == nil)
    }

    @Test func parseReturnsNilForADanglingOperator() {
        #expect(AdvancedSearchParser.parse("#a AND") == nil)
        #expect(AdvancedSearchParser.parse("OR #a") == nil)
    }

    // MARK: - Evaluation

    @Test func tagNodeMatchesCanonicalizedDocumentTags() {
        let node = AdvancedSearchParser.Node.tag("Act2")
        #expect(AdvancedSearchParser.matches(node, title: "", content: "", tags: ["act2"], defaultScope: .content))
        #expect(!AdvancedSearchParser.matches(node, title: "", content: "", tags: ["act3"], defaultScope: .content))
    }

    @Test func textNodeMatchesContentCaseInsensitively() {
        let node = AdvancedSearchParser.Node.text("dragon")
        #expect(AdvancedSearchParser.matches(node, title: "", content: "A Dragon appears.", tags: [], defaultScope: .content))
    }

    @Test func textNodeInPathScopeOnlyMatchesTitleNotContent() {
        let node = AdvancedSearchParser.Node.text("dragon")
        #expect(!AdvancedSearchParser.matches(node, title: "Chapter One", content: "A dragon appears.", tags: [], defaultScope: .path))
        #expect(AdvancedSearchParser.matches(node, title: "The Dragon's Lair", content: "", tags: [], defaultScope: .path))
    }

    @Test func andRequiresBothSides() {
        let node = AdvancedSearchParser.Node.and(.tag("character"), .tag("act2"))
        #expect(AdvancedSearchParser.matches(node, title: "", content: "", tags: ["character", "act2"], defaultScope: .content))
        #expect(!AdvancedSearchParser.matches(node, title: "", content: "", tags: ["character"], defaultScope: .content))
    }

    @Test func orRequiresEitherSide() {
        let node = AdvancedSearchParser.Node.or(.tag("villain"), .tag("hero"))
        #expect(AdvancedSearchParser.matches(node, title: "", content: "", tags: ["hero"], defaultScope: .content))
        #expect(!AdvancedSearchParser.matches(node, title: "", content: "", tags: ["bystander"], defaultScope: .content))
    }

    @Test func notInvertsTheOperand() {
        let node = AdvancedSearchParser.Node.not(.tag("resolved"))
        #expect(AdvancedSearchParser.matches(node, title: "", content: "", tags: ["character"], defaultScope: .content))
        #expect(!AdvancedSearchParser.matches(node, title: "", content: "", tags: ["resolved"], defaultScope: .content))
    }

    @Test func fullExamplePassesOnlyForCharacterAndAct2ButNotResolved() throws {
        let node = try #require(AdvancedSearchParser.parse("#character AND #act2 NOT #resolved"))
        #expect(AdvancedSearchParser.matches(node, title: "", content: "", tags: ["character", "act2"], defaultScope: .content))
        #expect(!AdvancedSearchParser.matches(node, title: "", content: "", tags: ["character", "act2", "resolved"], defaultScope: .content))
        #expect(!AdvancedSearchParser.matches(node, title: "", content: "", tags: ["character"], defaultScope: .content))
    }

    @Test func regexNodeMatchesAgainstContent() {
        let node = AdvancedSearchParser.Node.regex(#"^Chapter \d+"#)
        #expect(AdvancedSearchParser.matches(node, title: "", content: "Chapter 3: The Reveal", tags: [], defaultScope: .content))
        #expect(!AdvancedSearchParser.matches(node, title: "", content: "Some other text", tags: [], defaultScope: .content))
    }

    @Test func invalidRegexPatternFailsSafeAsNoMatchRatherThanCrashing() {
        let node = AdvancedSearchParser.Node.regex("(unterminated[")
        #expect(!AdvancedSearchParser.matches(node, title: "", content: "anything", tags: [], defaultScope: .content))
    }

    // MARK: - Regex safety

    @Test func isPotentiallyCatastrophicRejectsClassicNestedQuantifierShapes() {
        #expect(AdvancedSearchParser.isPotentiallyCatastrophic("(a+)+"))
        #expect(AdvancedSearchParser.isPotentiallyCatastrophic("(a*)*"))
        #expect(AdvancedSearchParser.isPotentiallyCatastrophic("(a+)*b"))
    }

    @Test func isPotentiallyCatastrophicAcceptsOrdinaryPatterns() {
        #expect(!AdvancedSearchParser.isPotentiallyCatastrophic(#"^Chapter \d+"#))
        #expect(!AdvancedSearchParser.isPotentiallyCatastrophic("[A-Za-z]+@[a-z]+\\.[a-z]+"))
    }

    @Test func isPotentiallyCatastrophicRejectsAbsurdlyLongPatterns() {
        #expect(AdvancedSearchParser.isPotentiallyCatastrophic(String(repeating: "a", count: 600)))
    }

    @Test func aRejectedCatastrophicPatternNeverMatches() {
        let node = AdvancedSearchParser.Node.regex("(a+)+$")
        #expect(!AdvancedSearchParser.matches(node, title: "", content: String(repeating: "a", count: 30) + "!", tags: [], defaultScope: .content))
    }

}
