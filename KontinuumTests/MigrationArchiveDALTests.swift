// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationArchiveDALTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

struct MigrationArchiveDALTests {

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

    @Test func archiveCopiesEveryFileInTheSourceVault() throws {
        let source = makeTempDirectory()
        write("Note one.", to: "One.md", in: source)
        write("Nested note.", to: "Projects/Two.md", in: source)

        let archivesRoot = makeTempDirectory()
        let libraryId = UUID()
        let destination = try MigrationArchiveDAL.archiveOriginalVault(sourceFolderURL: source, libraryId: libraryId, in: archivesRoot)

        #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent("One.md").path))
        #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent("Projects/Two.md").path))
    }

    @Test func archivedFileContentMatchesTheOriginalExactly() throws {
        let source = makeTempDirectory()
        let content = "Exact original content, unmodified."
        write(content, to: "Note.md", in: source)

        let archivesRoot = makeTempDirectory()
        let destination = try MigrationArchiveDAL.archiveOriginalVault(sourceFolderURL: source, libraryId: UUID(), in: archivesRoot)

        let archivedContent = try String(contentsOf: destination.appendingPathComponent("Note.md"), encoding: .utf8)
        #expect(archivedContent == content)
    }

    @Test func archivedFilesArePosixReadOnly() throws {
        let source = makeTempDirectory()
        write("Note.", to: "Note.md", in: source)

        let archivesRoot = makeTempDirectory()
        let destination = try MigrationArchiveDAL.archiveOriginalVault(sourceFolderURL: source, libraryId: UUID(), in: archivesRoot)

        let attributes = try FileManager.default.attributesOfItem(atPath: destination.appendingPathComponent("Note.md").path)
        let permissions = attributes[.posixPermissions] as? NSNumber
        #expect(permissions?.uint16Value == 0o444)
    }

    @Test func archivingDoesNotModifyTheOriginalSourceFiles() throws {
        let source = makeTempDirectory()
        write("Original.", to: "Note.md", in: source)

        let archivesRoot = makeTempDirectory()
        _ = try MigrationArchiveDAL.archiveOriginalVault(sourceFolderURL: source, libraryId: UUID(), in: archivesRoot)

        let sourceAttributes = try FileManager.default.attributesOfItem(atPath: source.appendingPathComponent("Note.md").path)
        let permissions = sourceAttributes[.posixPermissions] as? NSNumber
        #expect(permissions?.uint16Value != 0o444)
    }

    @Test func archivingTwiceForTheSameLibraryProducesTwoDistinctArchives() throws {
        let source = makeTempDirectory()
        write("Note.", to: "Note.md", in: source)

        let archivesRoot = makeTempDirectory()
        let libraryId = UUID()
        let first = try MigrationArchiveDAL.archiveOriginalVault(sourceFolderURL: source, libraryId: libraryId, in: archivesRoot)
        let second = try MigrationArchiveDAL.archiveOriginalVault(sourceFolderURL: source, libraryId: libraryId, in: archivesRoot)

        #expect(first != second)
        #expect(MigrationArchiveDAL.listArchives(libraryId: libraryId, in: archivesRoot).count == 2)
    }

    @Test func archivesAreScopedPerLibrary() throws {
        let source = makeTempDirectory()
        write("Note.", to: "Note.md", in: source)

        let archivesRoot = makeTempDirectory()
        let libraryId = UUID()
        _ = try MigrationArchiveDAL.archiveOriginalVault(sourceFolderURL: source, libraryId: libraryId, in: archivesRoot)

        #expect(MigrationArchiveDAL.listArchives(libraryId: UUID(), in: archivesRoot).isEmpty)
    }

}
