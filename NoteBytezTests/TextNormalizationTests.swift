// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TextNormalizationTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

/// Phase 1 (Unicode & Locale Correctness) — `Docs/Plans/NoteBytez20260823v2- HOLD
/// -MultiLanguage.md` decision G17.
struct TextNormalizationTests {

    @Test func normalizedComposesADecomposedCharacterToItsPrecomposedForm() {
        let decomposed = "cafe\u{0301}" // e + combining acute accent
        #expect(TextNormalization.normalized(decomposed) == "café")
        #expect(TextNormalization.normalized(decomposed).utf16.count == "café".utf16.count)
    }

    @Test func normalizedIsANoOpForAlreadyPrecomposedText() {
        #expect(TextNormalization.normalized("café") == "café")
    }

    @Test func invariantLowercasedLowercasesPlainLatinText() {
        #expect(TextNormalization.invariantLowercased("ROADMAP") == "roadmap")
    }

    @Test func invariantLowercasedFoldsTurkishDottedCapitalIWithoutLeavingUppercaseLetters() {
        #expect(!TextNormalization.invariantLowercased("İSTANBUL").contains(where: { $0.isUppercase }))
    }

    @Test func containsIgnoringCaseAndDiacriticsMatchesAnAccentedTarget() {
        #expect("Meet at the café.".containsIgnoringCaseAndDiacritics("cafe"))
        #expect("CAFÉ".containsIgnoringCaseAndDiacritics("cafe"))
    }

    @Test func containsIgnoringCaseAndDiacriticsReturnsFalseForAnEmptyNeedle() {
        #expect(!"Anything".containsIgnoringCaseAndDiacritics(""))
    }

    @Test func containsIgnoringCaseAndDiacriticsReturnsFalseForNoMatch() {
        #expect(!"Nothing relevant.".containsIgnoringCaseAndDiacritics("cafe"))
    }

}
