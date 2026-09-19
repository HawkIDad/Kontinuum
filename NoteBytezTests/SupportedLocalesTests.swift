// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SupportedLocalesTests.swift
//  NoteBytezTests
//

import Testing
@testable import NoteBytez

struct SupportedLocalesTests {

    /// Phase 6 (`en-US` baseline) + Phase 7 (Major Western European) + Phase 8 (Dutch, Nordics
    /// & Greek) + Phase 9 (CJK) + Phase 10 (remaining Success-Factor European languages).
    @Test func containsExactlyTheShippedTiers() {
        #expect(Set(SupportedLocales.all.map(\.id)) == ["en-US", "en-GB", "es", "fr", "de", "it", "pt-BR", "nl", "da", "el", "sv", "fi", "nb", "zh-Hans", "ja", "ko", "pl", "ro", "tr", "hu", "cs", "sr-Cyrl", "lt"])
    }

    @Test func everyEntryHasANonEmptyEndonym() {
        #expect(SupportedLocales.all.allSatisfy { !$0.endonym.isEmpty })
    }

    @Test func matchingDeviceReturnsTheExactLanguageWhenShipped() {
        #expect(SupportedLocales.matchingDevice(languageCode: "de").id == "de")
        #expect(SupportedLocales.matchingDevice(languageCode: "es").id == "es")
        #expect(SupportedLocales.matchingDevice(languageCode: "nl").id == "nl")
        #expect(SupportedLocales.matchingDevice(languageCode: "el").id == "el")
        #expect(SupportedLocales.matchingDevice(languageCode: "ja").id == "ja")
        #expect(SupportedLocales.matchingDevice(languageCode: "ko").id == "ko")
        // "zh-Hans" splits to language subtag "zh" — a device reporting plain "zh" still matches.
        #expect(SupportedLocales.matchingDevice(languageCode: "zh").id == "zh-Hans")
        #expect(SupportedLocales.matchingDevice(languageCode: "pl").id == "pl")
        #expect(SupportedLocales.matchingDevice(languageCode: "tr").id == "tr")
        // "sr-Cyrl" splits to language subtag "sr" — a device reporting plain "sr" still matches.
        #expect(SupportedLocales.matchingDevice(languageCode: "sr").id == "sr-Cyrl")
    }

    @Test func matchingDeviceFallsBackToTheFirstEntryWhenTheDeviceLanguageIsntShipped() {
        // Arabic isn't shipped yet (Phase 11, RTL, on hold) — G4b: fall back to the first
        // entry, never nil.
        #expect(SupportedLocales.matchingDevice(languageCode: "ar").id == "en-US")
    }

    @Test func matchingDeviceCannotDistinguishEnGBFromEnUSByLanguageSubtagAlone() {
        // Documents the known limitation on `matchingDevice` — both entries share the "en"
        // subtag, so a British device also resolves to `en-US` (harmless: `en-GB` currently
        // carries zero catalog overrides, so the two are byte-identical — see Phase 7.5).
        #expect(SupportedLocales.matchingDevice(languageCode: "en").id == "en-US")
    }

}
