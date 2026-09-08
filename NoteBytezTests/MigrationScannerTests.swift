// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationScannerTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

struct MigrationScannerTests {

    private func makeTempDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func write(_ content: String, to relativePath: String, in rootURL: URL) {
        let fileURL = rootURL.appendingPathComponent(relativePath)
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    // MARK: - Obsidian

    @Test func obsidianScanFindsMarkdownFilesAndCanvasFilesSeparately() {
        let root = makeTempDirectory()
        write("A note with [[a link]].", to: "Note.md", in: root)
        write("{\"nodes\":[],\"edges\":[]}", to: "Board.canvas", in: root)

        let result = MigrationScanner.scan(folderURL: root, format: .obsidian)

        #expect(result.pages.count == 1)
        #expect(result.canvasFiles.count == 1)
        #expect(result.canvasFiles.first?.boardName == "Board")
        #expect(result.journalPages.isEmpty)
    }

    @Test func obsidianScanCarriesYamlPropertiesThroughUnmodified() {
        let root = makeTempDirectory()
        write("---\nstatus: draft\n---\nBody.", to: "Note.md", in: root)

        let result = MigrationScanner.scan(folderURL: root, format: .obsidian)

        #expect(result.pages.first?.content.contains("status: draft") == true)
    }

    @Test func obsidianNoteCountIncludesOnlyPages() {
        let root = makeTempDirectory()
        write("One.", to: "One.md", in: root)
        write("Two.", to: "Two.md", in: root)

        let result = MigrationScanner.scan(folderURL: root, format: .obsidian)
        #expect(result.noteCount == 2)
    }

    // MARK: - Logseq

    @Test func logseqScanTranslatesTaskMarkersBeforeCountingTasks() {
        let root = makeTempDirectory()
        write("- TODO Buy milk\n- DONE Walk dog", to: "pages/Errands.md", in: root)

        let result = MigrationScanner.scan(folderURL: root, format: .logseq)

        #expect(result.pages.first?.taskCount == 2)
        #expect(result.pages.first?.content.contains("[ ] Buy milk") == true)
        #expect(result.pages.first?.content.contains("[x] Walk dog") == true)
    }

    @Test func logseqScanSeparatesJournalFilesFromOrdinaryPages() {
        let root = makeTempDirectory()
        write("- Ordinary page content", to: "pages/Ideas.md", in: root)
        write("- TODO Morning run", to: "journals/2024_01_15.md", in: root)

        let result = MigrationScanner.scan(folderURL: root, format: .logseq)

        #expect(result.pages.count == 1)
        #expect(result.pages.first?.relativePath == "pages/Ideas.md")
        #expect(result.journalPages.count == 1)
        #expect(result.journalPages.first?.summary.relativePath == "journals/2024_01_15.md")
    }

    @Test func logseqScanTreatsAJournalFileWithAnUnparsableNameAsAnOrdinaryPage() {
        let root = makeTempDirectory()
        write("- Some content", to: "journals/not-a-date.md", in: root)

        let result = MigrationScanner.scan(folderURL: root, format: .logseq)

        #expect(result.journalPages.isEmpty)
        #expect(result.pages.count == 1)
    }

    @Test func logseqScanCollectsUnsupportedQueriesAcrossFiles() {
        let root = makeTempDirectory()
        write("- {{query (and (page-tags \"a\") (page-tags \"b\"))}}", to: "pages/Query.md", in: root)

        let result = MigrationScanner.scan(folderURL: root, format: .logseq)

        #expect(result.unsupportedCount == 1)
    }

    @Test func logseqScanNeverProducesCanvasFiles() {
        let root = makeTempDirectory()
        write("- A bullet", to: "pages/Page.md", in: root)

        let result = MigrationScanner.scan(folderURL: root, format: .logseq)
        #expect(result.canvasFiles.isEmpty)
    }

    @Test func scanOfAnEmptyFolderReturnsAnEmptyResultForEitherFormat() {
        let root = makeTempDirectory()
        #expect(MigrationScanner.scan(folderURL: root, format: .obsidian).noteCount == 0)
        #expect(MigrationScanner.scan(folderURL: root, format: .logseq).noteCount == 0)
    }

}
