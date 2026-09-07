// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  StringSimilarityTests.swift
//  KontinuumTests
//

import Testing
@testable import Kontinuum

struct StringSimilarityTests {

    @Test func identicalStringsScoreOne() {
        #expect(StringSimilarity.similarity("Hello world", "Hello world") == 1.0)
    }

    @Test func completelyDisjointStringsScoreNearZero() throws {
        let score = try #require(StringSimilarity.similarity("aaaaaaaaaa", "bbbbbbbbbb"))
        #expect(score < 0.1)
    }

    @Test func oneWordEditInASentenceScoresAboveNinetyPercent() throws {
        let score = try #require(StringSimilarity.similarity(
            "The quick brown fox jumps over the lazy dog.",
            "The quick brown fox leaps over the lazy dog."
        ))
        #expect(score > 0.9)
    }

    @Test func lengthRatioBeyondBoundReturnsNilSentinel() {
        #expect(StringSimilarity.similarity("short", String(repeating: "x", count: 20)) == nil)
    }

    @Test func lengthBeyondFourThousandCharactersReturnsNilSentinelEvenWhenIdentical() {
        let long = String(repeating: "x", count: 4001)
        #expect(StringSimilarity.similarity(long, long) == nil)
    }

}
