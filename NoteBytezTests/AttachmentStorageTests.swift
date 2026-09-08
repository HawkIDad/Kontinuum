// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentStorageTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct AttachmentStorageTests {

    private func makeTempContainerRoot() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeSourceFile(named fileName: String, contents: String = "bytes") throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent(fileName)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    @Test func copyIntoContainerReturnsAContainerRootRelativePath() throws {
        let containerRoot = makeTempContainerRoot()
        let documentId = UUID()
        let attachmentId = UUID()
        let sourceFile = try makeSourceFile(named: "harbor.jpg")

        let relativePath = try AttachmentStorage.copyIntoContainer(sourceURL: sourceFile, documentId: documentId, attachmentId: attachmentId, fileName: "harbor.jpg", containerRoot: containerRoot)

        #expect(relativePath == "AttachmentStore/\(documentId.uuidString)/\(attachmentId.uuidString)-harbor.jpg")
        #expect(FileManager.default.fileExists(atPath: containerRoot.appendingPathComponent(relativePath).path))
    }

    @Test func copyIntoContainerSanitizesPathSeparatorsInTheFileName() throws {
        let containerRoot = makeTempContainerRoot()
        let documentId = UUID()
        let attachmentId = UUID()
        let sourceFile = try makeSourceFile(named: "not-a-path.jpg")

        let relativePath = try AttachmentStorage.copyIntoContainer(sourceURL: sourceFile, documentId: documentId, attachmentId: attachmentId, fileName: "evil/../name.jpg", containerRoot: containerRoot)

        // A sanitized filename has no "/" left, so `appendingPathComponent` can't escape the
        // document's own attachment directory regardless of the original name's `..` segments —
        // the written file must land inside `AttachmentStore/<documentId>/`, nowhere else.
        #expect(relativePath.hasPrefix("AttachmentStore/\(documentId.uuidString)/"))
        let resolvedPath = containerRoot.appendingPathComponent(relativePath).standardizedFileURL.path
        #expect(resolvedPath.hasPrefix(containerRoot.appendingPathComponent("AttachmentStore/\(documentId.uuidString)").standardizedFileURL.path))
        #expect(FileManager.default.fileExists(atPath: resolvedPath))
    }

    @Test func resolveReconstructsTheOnDiskURLFromARelativePath() {
        let containerRoot = makeTempContainerRoot()
        let resolved = AttachmentStorage.resolve(relativePath: "AttachmentStore/doc/file.jpg", containerRoot: containerRoot)
        #expect(resolved == containerRoot.appendingPathComponent("AttachmentStore/doc/file.jpg"))
    }

    @Test func isDownloadedIsTrueForAnOrdinaryLocalFile() throws {
        let sourceFile = try makeSourceFile(named: "local.jpg")
        // A plain local file (not inside an actual iCloud-backed container) has no ubiquitous
        // resource values, so this exercises the `fileExists` fallback branch.
        #expect(AttachmentStorage.isDownloaded(at: sourceFile))
    }

    @Test func isDownloadedIsFalseForAMissingFile() {
        let missingURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).jpg")
        #expect(!AttachmentStorage.isDownloaded(at: missingURL))
    }

}
