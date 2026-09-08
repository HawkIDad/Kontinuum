// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportScannerTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

struct ImportScannerTests {

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

    @Test func scanFindsEveryMarkdownFileRecursively() {
        let root = makeTempDirectory()
        write("First note.", to: "Root.md", in: root)
        write("Nested note.", to: "Projects/Kontinuum.md", in: root)

        let summaries = ImportScanner.scan(folderURL: root)

        #expect(summaries.count == 2)
        #expect(summaries.map { $0.relativePath }.sorted() == ["Projects/Kontinuum.md", "Root.md"])
    }

    @Test func scanIgnoresNonMarkdownFiles() {
        let root = makeTempDirectory()
        write("A note.", to: "Note.md", in: root)
        write("Not a note.", to: "image.png", in: root)

        let summaries = ImportScanner.scan(folderURL: root)

        #expect(summaries.count == 1)
        #expect(summaries.first?.relativePath == "Note.md")
    }

    @Test func scanDerivesTitleFromFilenameWithoutExtension() {
        let root = makeTempDirectory()
        write("Body.", to: "Weekly Review.md", in: root)

        let summaries = ImportScanner.scan(folderURL: root)

        #expect(summaries.first?.title == "Weekly Review")
    }

    @Test func scanCountsWikilinksAndTasksPerFile() throws {
        let root = makeTempDirectory()
        write("See [[Other Note]] and [[Another]].\n- [ ] Task one\n- [x] Task two", to: "Note.md", in: root)

        let summary = try #require(ImportScanner.scan(folderURL: root).first)

        #expect(summary.linkCount == 2)
        #expect(summary.taskCount == 2)
    }

    @Test func scanDetectsNotebooksFromFrontmatter() throws {
        let root = makeTempDirectory()
        write("---\nnotebooks: [\"App Onboarding Revamp\"]\n---\nElena Voss.", to: "Elena Voss.md", in: root)

        let summary = try #require(ImportScanner.scan(folderURL: root).first)

        #expect(summary.notebookNames == ["App Onboarding Revamp"])
    }

    @Test func scanOfAFileWithNoNotebooksFrontmatterReturnsEmptyNotebookNames() throws {
        let root = makeTempDirectory()
        write("Just a plain note.", to: "Note.md", in: root)

        let summary = try #require(ImportScanner.scan(folderURL: root).first)

        #expect(summary.notebookNames.isEmpty)
    }

    @Test func scanOfAnEmptyFolderReturnsNoFiles() {
        let root = makeTempDirectory()
        #expect(ImportScanner.scan(folderURL: root).isEmpty)
    }

    @Test func scanPreservesFileContentExactly() {
        let root = makeTempDirectory()
        let content = "# Heading\n\nSome body text with [[a link]] and #atag."
        write(content, to: "Note.md", in: root)

        #expect(ImportScanner.scan(folderURL: root).first?.content == content)
    }

}
