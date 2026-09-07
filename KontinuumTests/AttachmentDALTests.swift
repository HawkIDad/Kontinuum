// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentDALTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct AttachmentDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Attachment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    /// A temp directory stands in for the real iCloud ubiquity container — every `AttachmentDAL`
    /// entry point takes `containerRoot` as an explicit, overridable parameter for exactly this.
    private func makeTempContainerRoot() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func makeSourceFile(named fileName: String = "harbor.jpg", contents: String = "fake image bytes") throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent(fileName)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - attach

    @Test func attachCopiesTheFileAndCreatesTheRowAndEmbedLine() throws {
        let context = try makeContext()
        let containerRoot = makeTempContainerRoot()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Location Reference", content: "Notes about the harbor district.", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let sourceFile = try makeSourceFile()

        let result = try AttachmentDAL.attach(fileURL: sourceFile, mimeType: "image/jpeg", documentId: documentId, content: document.content ?? "", in: context, containerRoot: containerRoot)

        #expect(result.attachment.fileName == "harbor.jpg")
        #expect(result.content.contains("![harbor.jpg](harbor.jpg)"))
        #expect(AttachmentDAL.fetchActive(documentId: documentId, in: context).count == 1)

        let resolvedURL = try #require(AttachmentDAL.resolveLocalURL(result.attachment, containerRoot: containerRoot))
        #expect(FileManager.default.fileExists(atPath: resolvedURL.path))
    }

    @Test func attachThrowsWhenICloudIsUnavailable() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Note", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let sourceFile = try makeSourceFile()

        #expect(throws: AttachmentStorageError.self) {
            try AttachmentDAL.attach(fileURL: sourceFile, mimeType: "image/jpeg", documentId: documentId, content: "", in: context, containerRoot: nil)
        }
    }

    @Test func attachDedupesACollidingFileNameFinderStyle() throws {
        let context = try makeContext()
        let containerRoot = makeTempContainerRoot()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Location Reference", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let first = try AttachmentDAL.attach(fileURL: try makeSourceFile(contents: "one"), mimeType: "image/jpeg", documentId: documentId, content: "", in: context, containerRoot: containerRoot)
        let second = try AttachmentDAL.attach(fileURL: try makeSourceFile(contents: "two"), mimeType: "image/jpeg", documentId: documentId, content: first.content, in: context, containerRoot: containerRoot)

        #expect(first.attachment.fileName == "harbor.jpg")
        #expect(second.attachment.fileName == "harbor-2.jpg")
        #expect(AttachmentDAL.fetchActive(documentId: documentId, in: context).count == 2)
    }

    // MARK: - remove

    @Test func removeSoftDeletesTheRowButLeavesTheFileOnDisk() throws {
        let context = try makeContext()
        let containerRoot = makeTempContainerRoot()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Note", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let attached = try AttachmentDAL.attach(fileURL: try makeSourceFile(), mimeType: "image/jpeg", documentId: documentId, content: "", in: context, containerRoot: containerRoot)
        let resolvedURL = try #require(AttachmentDAL.resolveLocalURL(attached.attachment, containerRoot: containerRoot))

        AttachmentDAL.remove(attached.attachment, in: context)

        #expect(AttachmentDAL.fetchActive(documentId: documentId, in: context).isEmpty)
        #expect(FileManager.default.fileExists(atPath: resolvedURL.path))
    }

    // MARK: - syncAttachments (reconcile-on-save)

    @Test func syncAttachmentsSoftDeletesARowWhoseEmbedLineWasRemovedFromContent() throws {
        let context = try makeContext()
        let containerRoot = makeTempContainerRoot()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Note", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let attached = try AttachmentDAL.attach(fileURL: try makeSourceFile(), mimeType: "image/jpeg", documentId: documentId, content: "", in: context, containerRoot: containerRoot)

        let contentWithoutEmbed = AttachmentParser.removingEmbed(fileName: "harbor.jpg", from: attached.content)
        let remaining = AttachmentDAL.syncAttachments(for: documentId, content: contentWithoutEmbed, in: context)

        #expect(remaining.isEmpty)
        #expect(AttachmentDAL.fetchActive(documentId: documentId, in: context).isEmpty)
    }

    @Test func syncAttachmentsKeepsARowStillReferencedInContent() throws {
        let context = try makeContext()
        let containerRoot = makeTempContainerRoot()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Note", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let attached = try AttachmentDAL.attach(fileURL: try makeSourceFile(), mimeType: "image/jpeg", documentId: documentId, content: "", in: context, containerRoot: containerRoot)

        let remaining = AttachmentDAL.syncAttachments(for: documentId, content: attached.content, in: context)

        #expect(remaining.count == 1)
        #expect(AttachmentDAL.fetchActive(documentId: documentId, in: context).count == 1)
    }

}
