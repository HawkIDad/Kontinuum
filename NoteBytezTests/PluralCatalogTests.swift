// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluralCatalogTests.swift
//  NoteBytezTests
//
//  Phase 2.3 (G14): every hand-rolled `count == 1 ? "" : "s"` ternary was replaced with
//  `String(localized:)` over a singular-only source literal, backed by a `variations.plural`
//  entry in `Localizable.xcstrings`. This proves the mechanism actually resolves through the
//  compiled catalog at runtime (not just that the source compiles) — the value under test is
//  the real risk in this refactor: whether `String.LocalizationValue`'s `Int` interpolation
//  produces the `%lld`-keyed catalog lookup this phase's manually-authored entries assume.

import Testing
import Foundation
@testable import NoteBytez

struct PluralCatalogTests {

    @Test func bareNoteCountUsesTheCorrectCategoryForOneAndOther() {
        #expect(String(localized: "\(1) note") == "1 note")
        #expect(String(localized: "\(2) note") == "2 notes")
        #expect(String(localized: "\(0) note") == "0 notes")
    }

    @Test func irregularPluralsResolveTheHandWrittenOtherForm() {
        #expect(String(localized: "\(1) canvas") == "1 canvas")
        #expect(String(localized: "\(3) canvas") == "3 canvases")
        #expect(String(localized: "\(1) journal entry") == "1 journal entry")
        #expect(String(localized: "\(4) journal entry") == "4 journal entries")
    }

    @Test func fullSentenceKeysStillCarryTheirSurroundingText() {
        #expect(String(localized: "Depth: \(1) hop") == "Depth: 1 hop")
        #expect(String(localized: "Depth: \(3) hop") == "Depth: 3 hops")
        #expect(String(localized: "Conflict on \(1) note") == "Conflict on 1 note")
        #expect(String(localized: "Conflict on \(5) note") == "Conflict on 5 notes")
    }

    @Test func stringInterpolationAlongsideAnIntegerStillResolvesThePluralCategory() {
        let verb = "received"
        #expect(String(localized: "Synced — \(1) note \(verb)") == "Synced — 1 note received")
        #expect(String(localized: "Synced — \(2) note \(verb)") == "Synced — 2 notes received")
    }

}
