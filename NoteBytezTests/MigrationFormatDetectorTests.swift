// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationFormatDetectorTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct MigrationFormatDetectorTests {

    private func makeTempDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test func detectsObsidianFromItsMarkerFolder() {
        let root = makeTempDirectory()
        try? FileManager.default.createDirectory(at: root.appendingPathComponent(".obsidian"), withIntermediateDirectories: true)

        #expect(MigrationFormatDetector.detect(folderURL: root) == .obsidian)
    }

    @Test func detectsLogseqFromItsMarkerFolder() {
        let root = makeTempDirectory()
        try? FileManager.default.createDirectory(at: root.appendingPathComponent("logseq"), withIntermediateDirectories: true)

        #expect(MigrationFormatDetector.detect(folderURL: root) == .logseq)
    }

    @Test func returnsNilWhenNeitherMarkerIsPresent() {
        let root = makeTempDirectory()
        try? "A plain note.".write(to: root.appendingPathComponent("Note.md"), atomically: true, encoding: .utf8)

        #expect(MigrationFormatDetector.detect(folderURL: root) == nil)
    }

    @Test func aPlainFileNamedLogseqIsNotMistakenForTheMarkerFolder() {
        let root = makeTempDirectory()
        try? "not a folder".write(to: root.appendingPathComponent("logseq"), atomically: true, encoding: .utf8)

        #expect(MigrationFormatDetector.detect(folderURL: root) == nil)
    }

    @Test func obsidianTakesPrecedenceWhenBothMarkersSomehowExist() {
        let root = makeTempDirectory()
        try? FileManager.default.createDirectory(at: root.appendingPathComponent(".obsidian"), withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: root.appendingPathComponent("logseq"), withIntermediateDirectories: true)

        #expect(MigrationFormatDetector.detect(folderURL: root) == .obsidian)
    }

}
