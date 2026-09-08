// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ExportDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct ExportDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self, DocumentNotebook.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func makeTempDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test func exportDocumentWritesExactContentToATitledFile() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Weekly Review", content: "- [ ] Review PRs", libraryId: libraryId, in: context)

        try ExportDAL.exportDocument(document, to: directory, in: context)

        let fileURL = directory.appendingPathComponent("Weekly Review.md")
        #expect(try String(contentsOf: fileURL, encoding: .utf8) == "- [ ] Review PRs")
    }

    @Test func exportDocumentWritesTheLiteralEmbedSigilRatherThanItsExpandedContent() throws {
        // Decision 5: `!((anchor))` transclusion is render-time only — the exported file must
        // still carry the literal sigil, so Obsidian/Logseq opening it sees inert text, not a
        // proprietary expansion baked into the note.
        let context = try makeContext()
        let directory = makeTempDirectory()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Journal Entry", content: "See !((review-pr)) for the live copy.", libraryId: libraryId, in: context)

        try ExportDAL.exportDocument(document, to: directory, in: context)

        let fileURL = directory.appendingPathComponent("Journal Entry.md")
        #expect(try String(contentsOf: fileURL, encoding: .utf8) == "See !((review-pr)) for the live copy.")
    }

    @Test func exportDocumentSanitizesPathSeparatorsInTheTitle() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Q1/Q2 Planning", content: "Body", libraryId: libraryId, in: context)

        try ExportDAL.exportDocument(document, to: directory, in: context)

        let contents = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        #expect(contents == ["Q1-Q2 Planning.md"])
    }

    @Test func exportLibraryWritesOneFilePerActiveDocument() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "One", content: "First", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Two", content: "Second", libraryId: libraryId, in: context)

        let count = ExportDAL.exportLibrary(libraryId: libraryId, to: directory, in: context)

        #expect(count == 2)
        let filenames = Set((try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? [])
        #expect(filenames == ["One.md", "Two.md"])
    }

    @Test func exportLibraryExcludesSoftDeletedDocuments() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Deleted", content: "Gone", libraryId: libraryId, in: context)
        DocumentDAL.softDelete(document, in: context)
        _ = DocumentDAL.create(title: "Kept", content: "Stays", libraryId: libraryId, in: context)

        let count = ExportDAL.exportLibrary(libraryId: libraryId, to: directory, in: context)

        #expect(count == 1)
        let filenames = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
        #expect(filenames == ["Kept.md"])
    }

    @Test func exportableContentIsUnchangedForADocumentInNoNotebooks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Plain Note", content: "Just some text.", libraryId: libraryId, in: context)

        #expect(ExportDAL.exportableContent(for: document, in: context) == "Just some text.")
    }

    @Test func exportableContentAddsNotebooksFrontmatterAndSyntheticTag() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elena Voss", content: "A wandering engineer.", libraryId: libraryId, in: context)
        let notebook = NotebookDAL.create(name: "App Onboarding Revamp", libraryId: libraryId, in: context)
        NotebookDAL.attach(documentId: try #require(document.documentId), notebookId: try #require(notebook.notebookId), libraryId: libraryId, in: context)

        let exported = ExportDAL.exportableContent(for: document, in: context)

        #expect(exported.hasPrefix("---\n"))
        #expect(exported.contains("notebooks: [\"App Onboarding Revamp\"]"))
        #expect(exported.contains("A wandering engineer."))
        #expect(exported.contains("#notebook/app-onboarding-revamp"))
        #expect(NotebookParser.extractFrontmatterNotebooks(from: exported) == ["App Onboarding Revamp"])
    }

    @Test func exportableContentListsEveryNotebookMembershipAndKebabCasesEachTag() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Shared Technology", content: "FTL drive specs.", libraryId: libraryId, in: context)
        let notebookOne = NotebookDAL.create(name: "Book Series One", libraryId: libraryId, in: context)
        let notebookTwo = NotebookDAL.create(name: "Book Series Two", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        NotebookDAL.attach(documentId: documentId, notebookId: try #require(notebookOne.notebookId), libraryId: libraryId, in: context)
        NotebookDAL.attach(documentId: documentId, notebookId: try #require(notebookTwo.notebookId), libraryId: libraryId, in: context)

        let exported = ExportDAL.exportableContent(for: document, in: context)

        #expect(exported.contains("#notebook/book-series-one"))
        #expect(exported.contains("#notebook/book-series-two"))
        #expect(Set(NotebookParser.extractFrontmatterNotebooks(from: exported)) == ["Book Series One", "Book Series Two"])
    }

    @Test func exportableContentPreservesExistingFrontmatterWhenAddingNotebooks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "---\ntags: [roadmap]\n---\nBody text.", libraryId: libraryId, in: context)
        let notebook = NotebookDAL.create(name: "NoteBytez Roadmap", libraryId: libraryId, in: context)
        NotebookDAL.attach(documentId: try #require(document.documentId), notebookId: try #require(notebook.notebookId), libraryId: libraryId, in: context)

        let exported = ExportDAL.exportableContent(for: document, in: context)

        #expect(exported.contains("tags: [roadmap]"))
        #expect(exported.contains("notebooks: [\"NoteBytez Roadmap\"]"))
        #expect(exported.contains("Body text."))
    }

    @Test func exportableContentDoesNotAccumulateDuplicateNotebooksLinesOnReExport() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "Original body.", libraryId: libraryId, in: context)
        let notebook = NotebookDAL.create(name: "NoteBytez Roadmap", libraryId: libraryId, in: context)
        NotebookDAL.attach(documentId: try #require(document.documentId), notebookId: try #require(notebook.notebookId), libraryId: libraryId, in: context)

        let firstExport = ExportDAL.exportableContent(for: document, in: context)
        document.content = firstExport
        let secondExport = ExportDAL.exportableContent(for: document, in: context)

        let occurrences = secondExport.components(separatedBy: "notebooks:").count - 1
        #expect(occurrences == 1)
    }

}
