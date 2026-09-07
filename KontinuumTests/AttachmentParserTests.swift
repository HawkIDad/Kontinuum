// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentParserTests.swift
//  KontinuumTests
//

import Testing
@testable import Kontinuum

struct AttachmentParserTests {

    // MARK: - containsAttachmentEmbed

    @Test func containsAttachmentEmbedDetectsAnImageLine() {
        #expect(AttachmentParser.containsAttachmentEmbed("Some notes.\n\n![harbor.jpg](harbor.jpg)"))
    }

    @Test func containsAttachmentEmbedIsFalseForPlainContent() {
        #expect(!AttachmentParser.containsAttachmentEmbed("Just a plain note with a [[wikilink]] and a #tag."))
    }

    // MARK: - match

    @Test func matchExtractsAltTextAndFileName() {
        let match = AttachmentParser.match(in: "![Harbor district](harbor.jpg)")
        #expect(match?.altText == "Harbor district")
        #expect(match?.fileName == "harbor.jpg")
    }

    @Test func matchReturnsNilForANonImageLine() {
        #expect(AttachmentParser.match(in: "Just some prose.") == nil)
    }

    @Test func matchIgnoresAWikilinkOnTheSameLine() {
        #expect(AttachmentParser.match(in: "See [[Harbor District]] for more.") == nil)
    }

    // MARK: - referencedFileNames

    @Test func referencedFileNamesCollectsEveryEmbedInContent() {
        let content = "![a](harbor.jpg)\n\nSome text.\n\n![b](lease.pdf)"
        let names = AttachmentParser.referencedFileNames(in: content)
        #expect(names == ["harbor.jpg", "lease.pdf"])
    }

    @Test func referencedFileNamesIsEmptyForContentWithNoEmbeds() {
        #expect(AttachmentParser.referencedFileNames(in: "No images here.").isEmpty)
    }

    // MARK: - applying

    @Test func applyingAppendsAnEmbedLineToNonEmptyContent() {
        let result = AttachmentParser.applying(fileName: "harbor.jpg", altText: "harbor.jpg", to: "Notes about the harbor district.")
        #expect(result == "Notes about the harbor district.\n\n![harbor.jpg](harbor.jpg)")
    }

    @Test func applyingToEmptyContentIsJustTheEmbed() {
        let result = AttachmentParser.applying(fileName: "harbor.jpg", altText: "harbor.jpg", to: "")
        #expect(result == "![harbor.jpg](harbor.jpg)")
    }

    // MARK: - removingEmbed

    @Test func removingEmbedStripsOnlyTheMatchingLine() {
        let content = "Intro.\n![harbor.jpg](harbor.jpg)\n![lease.pdf](lease.pdf)\nOutro."
        let result = AttachmentParser.removingEmbed(fileName: "harbor.jpg", from: content)
        #expect(!result.contains("harbor.jpg"))
        #expect(result.contains("lease.pdf"))
        #expect(result.contains("Intro."))
        #expect(result.contains("Outro."))
    }

    @Test func removingEmbedForAnUnreferencedFileNameIsANoOp() {
        let content = "![lease.pdf](lease.pdf)"
        #expect(AttachmentParser.removingEmbed(fileName: "harbor.jpg", from: content) == content)
    }

}
