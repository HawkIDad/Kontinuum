// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Phase2PseudolocalizationTests.swift
//  NoteBytezUITests
//
//  Phase 2.7 of NoteBytez20260823v2- HOLD -MultiLanguage.md. Launches under Apple's
//  double-length pseudolocalization (`Scripts/run-pseudolocalized.sh double-length`'s same
//  `-NSDoubleLocalizedStrings YES` flag) and walks the key-screen set, asserting no visible
//  text is a raw, unresolved format specifier (`%@`, `%lld`, `%1$@`, `%#@...@`) — the shape a
//  broken String Catalog lookup or a malformed positional specifier would leak to the screen.
//

import XCTest

final class Phase2PseudolocalizationTests: NoteBytezUITestCase {

    /// A raw specifier leaking to the screen means the catalog lookup or substitution failed —
    /// the user should never see `%@`/`%lld`/`%1$@`/`%#@name@` literally.
    private static let rawKeyPattern = try! NSRegularExpression(pattern: #"%(\d+\$)?(@|lld|ld|d)|%#@\w+@"#)

    private func assertNoRawFormatSpecifiers(on screenName: String, file: StaticString = #filePath, line: UInt = #line) {
        let allLabels = app.staticTexts.allElementsBoundByIndex.map(\.label)
            + app.buttons.allElementsBoundByIndex.map(\.label)

        let offenders = allLabels.filter { label in
            let range = NSRange(label.startIndex..., in: label)
            return Self.rawKeyPattern.firstMatch(in: label, range: range) != nil
        }

        XCTAssertTrue(
            offenders.isEmpty,
            "\(offenders.count) raw format specifier leak(s) on \(screenName): \(offenders.prefix(5))",
            file: file, line: line
        )
    }

    @MainActor
    func testNoRawFormatSpecifiersAcrossMainScreensUnderDoubleLengthPseudolocalization() throws {
        launchAndCreateLibrary(extraArguments: ["-NSDoubleLocalizedStrings", "YES"])

        let today = TodayJournalScreen(app: app)
        XCTAssertTrue(today.editor.waitForExistence(timeout: 5))
        assertNoRawFormatSpecifiers(on: "Today")

        MainShellScreen(app: app).navigate(to: "Notebooks")
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
        assertNoRawFormatSpecifiers(on: "Notebooks (empty)")

        MainShellScreen(app: app).navigate(to: "Search")
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
        assertNoRawFormatSpecifiers(on: "Search")

        MainShellScreen(app: app).navigate(to: "Settings")
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
        assertNoRawFormatSpecifiers(on: "Settings")
    }

}
