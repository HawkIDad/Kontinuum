// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LogseqImporterTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct LogseqImporterTests {

    // MARK: - Task marker translation

    @Test func translatesATodoBulletToAnOpenCheckbox() {
        let result = LogseqImporter.transform("- TODO Buy milk")
        #expect(result.content == "- [ ] Buy milk")
    }

    @Test func translatesADoneBulletToACheckedCheckbox() {
        let result = LogseqImporter.transform("- DONE Buy milk")
        #expect(result.content == "- [x] Buy milk")
    }

    @Test func leavesAPlainBulletUntranslated() {
        let result = LogseqImporter.transform("- Just a note")
        #expect(result.content == "- Just a note")
    }

    @Test func leavesAnUnhandledLogseqKeywordAsPlainText() {
        // DOING/NOW/LATER/WAITING/CANCELED are out of this importer's stated scope (TODO/DONE
        // only) — left untranslated rather than guessed at.
        let result = LogseqImporter.transform("- DOING Buy milk")
        #expect(result.content == "- DOING Buy milk")
    }

    // MARK: - Block grouping (blank line before each top-level bullet)

    @Test func insertsABlankLineBetweenTopLevelBulletsSoEachBecomesItsOwnBlock() {
        let result = LogseqImporter.transform("- First\n- Second")
        #expect(result.content == "- First\n\n- Second")
    }

    @Test func keepsNestedBulletsAttachedToTheirParentWithNoBlankLine() {
        let result = LogseqImporter.transform("- Parent\n\t- Child")
        #expect(result.content == "- Parent\n\t- Child")
    }

    @Test func aSingleTopLevelBulletGetsNoLeadingBlankLine() {
        let result = LogseqImporter.transform("- Only bullet")
        #expect(result.content == "- Only bullet")
    }

    @Test func nonBulletLinesPassThroughUnchanged() {
        let result = LogseqImporter.transform("# A heading\n\n- A bullet")
        #expect(result.content == "# A heading\n\n- A bullet")
    }

    // MARK: - {{query}} mapping

    @Test func mapsAQuotedTextQueryToAnEmbeddedQueryBlock() {
        let result = LogseqImporter.transform(#"- {{query "project ideas"}}"#)
        #expect(result.content == "```query\nproject ideas\n```")
        #expect(result.unsupportedQueries.isEmpty)
    }

    @Test func mapsAPageTagsQueryToAHashtagEmbeddedQueryBlock() {
        let result = LogseqImporter.transform(#"- {{query (page-tags "recipe")}}"#)
        #expect(result.content == "```query\n#recipe\n```")
        #expect(result.unsupportedQueries.isEmpty)
    }

    @Test func mapsAnUnquotedPageTagsQueryToAHashtagEmbeddedQueryBlock() {
        let result = LogseqImporter.transform("- {{query (page-tags recipe)}}")
        #expect(result.content == "```query\n#recipe\n```")
    }

    @Test func flagsAnUnsupportedBooleanQueryRatherThanGuessing() {
        let query = #"{{query (and (page-tags "recipe") (page-tags "easy"))}}"#
        let result = LogseqImporter.transform("- \(query)")

        #expect(result.unsupportedQueries == [query])
        #expect(result.content.contains("Unsupported Logseq query"))
        #expect(result.content.contains(query))
    }

    @Test func aResolvedQueryProducesNoUnsupportedEntry() {
        let result = LogseqImporter.transform(#"- {{query "text"}}"#)
        #expect(result.unsupportedQueries.isEmpty)
    }

    // MARK: - Journal detection

    @Test func isJournalFileWhenPathIsUnderAJournalsFolder() {
        #expect(LogseqImporter.isJournalFile(relativePath: "journals/2024_01_15.md"))
    }

    @Test func isJournalFileIsCaseInsensitiveToTheFolderName() {
        #expect(LogseqImporter.isJournalFile(relativePath: "Journals/2024_01_15.md"))
    }

    @Test func isNotAJournalFileWhenOutsideAJournalsFolder() {
        #expect(LogseqImporter.isJournalFile(relativePath: "pages/Project Ideas.md") == false)
    }

    @Test func parsesTheClassicUnderscoreJournalDateFormat() throws {
        let date = LogseqImporter.journalDate(forFileNamed: "2024_01_15.md")
        let components = Calendar.current.dateComponents([.year, .month, .day], from: try #require(date))
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 15)
    }

    @Test func parsesTheHyphenJournalDateFormat() throws {
        let date = LogseqImporter.journalDate(forFileNamed: "2024-01-15.md")
        let components = Calendar.current.dateComponents([.year, .month, .day], from: try #require(date))
        #expect(components.year == 2024)
        #expect(components.month == 1)
        #expect(components.day == 15)
    }

    @Test func returnsNilForANonDateJournalFilename() {
        #expect(LogseqImporter.journalDate(forFileNamed: "Project Ideas.md") == nil)
    }

}
