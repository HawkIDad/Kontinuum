// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct ImportDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self, DocumentNotebook.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func summary(title: String, content: String, notebookNames: [String] = []) -> ImportFileSummary {
        ImportFileSummary(
            relativePath: "\(title).md",
            title: title,
            content: content,
            linkCount: WikilinkParser.extractTitles(from: content).count,
            taskCount: TaskParser.extractTasks(from: content).count,
            notebookNames: notebookNames
        )
    }

    @Test func importFilesCreatesOneDocumentPerSummary() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let summaries = [summary(title: "One", content: "First"), summary(title: "Two", content: "Second")]

        let count = ImportDAL.importFiles(summaries, libraryId: libraryId, in: context)

        #expect(count == 2)
        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(documents.count == 2)
        #expect(Set(documents.compactMap { $0.title }) == ["One", "Two"])
    }

    @Test func importFilesPreservesContentAndSplitsBlocks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let content = "First paragraph.\n\nSecond paragraph."

        ImportDAL.importFiles([summary(title: "Note", content: content)], libraryId: libraryId, in: context)

        let document = try #require(DocumentDAL.fetchActive(libraryId: libraryId, in: context).first)
        #expect(document.content == content)
        let documentId = try #require(document.documentId)
        #expect(BlockDAL.fetchActive(documentId: documentId, in: context).count == 2)
    }

    @Test func importFilesIndexesTagsAndTasks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let content = "#roadmap\n- [ ] Ship it\n- [x] Plan it"

        ImportDAL.importFiles([summary(title: "Note", content: content)], libraryId: libraryId, in: context)

        let document = try #require(DocumentDAL.fetchActive(libraryId: libraryId, in: context).first)
        let documentId = try #require(document.documentId)

        #expect(TagDAL.fetchTags(for: documentId, in: context).map { $0.name } == ["roadmap"])
        let tasks = TaskDAL.fetchActive(documentId: documentId, in: context)
        #expect(tasks.count == 2)
        #expect(tasks.filter { $0.isDone == true }.count == 1)
    }

    @Test func importedWikilinksResolveAsBacklinksWithoutAnySeparateStep() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let summaries = [
            summary(title: "Target Note", content: "The destination."),
            summary(title: "Source Note", content: "See [[Target Note]] for details.")
        ]

        ImportDAL.importFiles(summaries, libraryId: libraryId, in: context)

        let target = try #require(DocumentDAL.fetchActive(libraryId: libraryId, in: context).first { $0.title == "Target Note" })
        let targetId = try #require(target.documentId)

        let backlinks = BacklinkDAL.findBacklinks(to: "Target Note", excluding: targetId, libraryId: libraryId, in: context)
        #expect(backlinks.count == 1)
        #expect(backlinks.first?.sourceDocument.title == "Source Note")
    }

    @Test func importFilesCreatesAndAttachesNotebooksFromFrontmatter() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let content = "---\nnotebooks: [\"App Onboarding Revamp\"]\n---\nElena Voss, a wandering engineer."

        ImportDAL.importFiles([summary(title: "Elena Voss", content: content, notebookNames: ["App Onboarding Revamp"])], libraryId: libraryId, in: context)

        let document = try #require(DocumentDAL.fetchActive(libraryId: libraryId, in: context).first)
        let documentId = try #require(document.documentId)
        let notebooks = NotebookDAL.fetchNotebooks(for: documentId, in: context)

        #expect(notebooks.map { $0.name } == ["App Onboarding Revamp"])
    }

    @Test func importFilesReusesAnExistingNotebookByExactNameRatherThanDuplicating() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let summaries = [
            summary(title: "Elena Voss", content: "Character one.", notebookNames: ["App Onboarding Revamp"]),
            summary(title: "Marcus Reyes", content: "Character two.", notebookNames: ["App Onboarding Revamp"])
        ]

        ImportDAL.importFiles(summaries, libraryId: libraryId, in: context)

        #expect(NotebookDAL.fetchActive(libraryId: libraryId, in: context).count == 1)
        let notebook = try #require(NotebookDAL.fetchActive(libraryId: libraryId, in: context).first)
        #expect(NotebookDAL.fetchDocuments(for: notebook, in: context).count == 2)
    }

    @Test func importFilesWithNoNotebooksFrontmatterCreatesNoNotebooks() throws {
        let context = try makeContext()
        let libraryId = UUID()

        ImportDAL.importFiles([summary(title: "Plain Note", content: "No notebooks here.")], libraryId: libraryId, in: context)

        #expect(NotebookDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)
    }

}
