// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  StringExtractorTests.swift
//  translate-strings-tests
//

import Testing
@testable import translate_strings

struct StringExtractorTests {

    @Test func extractsAPlainTextLiteral() {
        let found = StringExtractor.extract(from: #"Text("Hello")"#, fileName: "Sample.swift")
        #expect(found.map { $0.key } == ["Hello"])
    }

    @Test func attachesThePrecedingLineCommentAsContext() {
        let source = """
        // Shown when the library has nothing in it yet.
        Text("No Notes Yet")
        """
        let found = StringExtractor.extract(from: source, fileName: "Sample.swift")
        #expect(found.first?.comment == "Shown when the library has nothing in it yet.")
    }

    @Test func skipsInterpolatedLiterals() {
        let found = StringExtractor.extract(from: #"Text("Hello \(name)")"#, fileName: "Sample.swift")
        #expect(found.isEmpty)
    }

    @Test func skipsEmptyLiterals() {
        let found = StringExtractor.extract(from: #"Text("")"#, fileName: "Sample.swift")
        #expect(found.isEmpty)
    }

    @Test func extractsANavigationTitle() {
        let found = StringExtractor.extract(from: #".navigationTitle("Sync Status")"#, fileName: "Sample.swift")
        #expect(found.map { $0.key } == ["Sync Status"])
    }

    @Test func extractsALabelsTitleArgumentOnly() {
        let found = StringExtractor.extract(from: #"Label("Today", systemImage: "square.and.pencil")"#, fileName: "Sample.swift")
        #expect(found.map { $0.key } == ["Today"])
    }

    @Test func extractsAButtonTitle() {
        let found = StringExtractor.extract(from: #"Button("Sync Now") { viewModel.syncNow() }"#, fileName: "Sample.swift")
        #expect(found.map { $0.key } == ["Sync Now"])
    }

    @Test func recordsTheOneBasedLineNumber() {
        let source = "let x = 1\nText(\"Second Line\")"
        let found = StringExtractor.extract(from: source, fileName: "Sample.swift")
        #expect(found.first?.line == 2)
    }

    @Test func findsMultipleLiteralsOnDifferentLines() {
        let source = """
        Text("First")
        Text("Second")
        """
        let found = StringExtractor.extract(from: source, fileName: "Sample.swift")
        #expect(found.map { $0.key } == ["First", "Second"])
    }

    @Test func extractsAStringLocalizedLiteral() {
        let found = StringExtractor.extract(from: #"String(localized: "Synced")"#, fileName: "Sample.swift")
        #expect(found.map { $0.key } == ["Synced"])
    }

    @Test func skipsInterpolatedStringLocalizedLiterals() {
        let found = StringExtractor.extract(from: #"String(localized: "Conflict on \(count) notes")"#, fileName: "Sample.swift")
        #expect(found.isEmpty)
    }

    @Test func hasNoCommentWhenThePrecedingLineIsNotAComment() {
        let source = """
        let spacer = 8
        Text("No Context")
        """
        let found = StringExtractor.extract(from: source, fileName: "Sample.swift")
        #expect(found.first?.comment == nil)
    }

}
