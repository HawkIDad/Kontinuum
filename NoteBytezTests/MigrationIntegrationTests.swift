// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationIntegrationTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

/// Journey 9 end-to-end: scan a fixture vault → confirm migration → spot-check the resulting
/// library, for both source formats plus the two cross-cutting requirements (unsupported-query
/// flagging, archive preservation) that apply regardless of format.
struct MigrationIntegrationTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self, DocumentNotebook.self,
            TaskItem.self, Property.self, DocumentProperty.self, Attachment.self, CanvasBoard.self, CanvasCard.self, CanvasConnector.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

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

    // MARK: - Obsidian fixture-vault round-trip (wikilinks/properties/canvas)

    @Test func obsidianVaultMigratesWikilinksPropertiesAndCanvas() throws {
        let vault = makeTempDirectory()
        try FileManager.default.createDirectory(at: vault.appendingPathComponent(".obsidian"), withIntermediateDirectories: true)
        write("---\nstatus: draft\n---\nSee [[Sync Log]] for details.", to: "Aria.md", in: vault)
        write("# Sync Log\n\nFixed the race condition.", to: "Sync Log.md", in: vault)
        write(#"{"nodes":[{"id":"n1","type":"file","x":0,"y":0,"width":100,"height":100,"file":"Aria.md"}],"edges":[]}"#, to: "Board.canvas", in: vault)

        #expect(MigrationFormatDetector.detect(folderURL: vault) == .obsidian)

        let context = try makeContext()
        let library = LibraryDAL.create(name: "Obsidian Import", in: context)
        let libraryId = try #require(library.libraryId)

        let result = MigrationScanner.scan(folderURL: vault, format: .obsidian)
        #expect(result.noteCount == 2)
        #expect(result.canvasCount == 1)

        MigrationDAL.commit(result, libraryId: libraryId, in: context)

        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(documents.count == 2)

        let aria = try #require(documents.first { $0.title == "Aria" })
        let ariaId = try #require(aria.documentId)
        let properties = PropertyDAL.fetchProperties(for: ariaId, in: context)
        #expect(properties.contains { $0.property.name == "status" && $0.value == "draft" })

        let boards = CanvasDAL.fetchActiveBoards(libraryId: libraryId, in: context)
        #expect(boards.count == 1)
        let cards = try #require(boards.first?.canvasBoardId).map { CanvasDAL.fetchActiveCards(boardId: $0, in: context) } ?? []
        #expect(cards.first?.documentId == ariaId)
    }

    // MARK: - Logseq fixture-vault round-trip (blocks/journals/tasks)

    @Test func logseqVaultMigratesTasksAndJournalEntries() throws {
        let vault = makeTempDirectory()
        try FileManager.default.createDirectory(at: vault.appendingPathComponent("logseq"), withIntermediateDirectories: true)
        write("- TODO Write chapter one\n- DONE Outline the plot", to: "pages/Novel.md", in: vault)
        write("- TODO Morning pages\n- Went for a walk", to: "journals/2024_01_15.md", in: vault)

        #expect(MigrationFormatDetector.detect(folderURL: vault) == .logseq)

        let context = try makeContext()
        let library = LibraryDAL.create(name: "Logseq Import", in: context)
        let libraryId = try #require(library.libraryId)

        let result = MigrationScanner.scan(folderURL: vault, format: .logseq)
        #expect(result.pages.count == 1)
        #expect(result.journalPages.count == 1)

        MigrationDAL.commit(result, libraryId: libraryId, in: context)

        let novel = try #require(DocumentDAL.fetchActive(libraryId: libraryId, in: context).first { $0.title == "Novel" })
        let novelId = try #require(novel.documentId)
        let novelTasks = TaskDAL.fetchActive(documentId: novelId, in: context)
        #expect(novelTasks.count == 2)
        #expect(novelTasks.contains { $0.isDone == true })
        #expect(novelTasks.contains { $0.isDone == false })

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let journalDate = calendar.date(from: DateComponents(year: 2024, month: 1, day: 15))!
        let journalEntry = try #require(JournalDAL.fetch(for: journalDate, libraryId: libraryId, in: context))
        #expect(journalEntry.content?.contains("[ ] Morning pages") == true)
        #expect(journalEntry.isJournalEntry == true)
    }

    // MARK: - Unsupported-query-pattern flagging

    @Test func unsupportedLogseqQueryIsFlaggedNotSilentlyDropped() throws {
        let vault = makeTempDirectory()
        let unsupportedQuery = #"{{query (and (page-tags "recipe") (page-tags "easy"))}}"#
        write("- \(unsupportedQuery)", to: "pages/Query.md", in: vault)

        let context = try makeContext()
        let library = LibraryDAL.create(name: "Logseq Import", in: context)
        let libraryId = try #require(library.libraryId)

        let result = MigrationScanner.scan(folderURL: vault, format: .logseq)
        #expect(result.unsupportedQueries == [unsupportedQuery])

        MigrationDAL.commit(result, libraryId: libraryId, in: context)

        let document = try #require(DocumentDAL.fetchActive(libraryId: libraryId, in: context).first)
        #expect(document.content?.contains("Unsupported Logseq query") == true)
        #expect(document.content?.contains(unsupportedQuery) == true)
    }

    // MARK: - Archive-preservation correctness

    @Test func confirmingAMigrationArchivesTheOriginalVault() throws {
        let vault = makeTempDirectory()
        write("A note.", to: "Note.md", in: vault)

        let context = try makeContext()
        let library = LibraryDAL.create(name: "Archived Import", in: context)
        let libraryId = try #require(library.libraryId)

        let archivesRoot = makeTempDirectory()
        let viewModel = MigrationViewModel(library: library, folderURL: vault, modelContext: context)
        MigrationDAL.commit(viewModel.scanResult, libraryId: libraryId, in: context)
        let destination = try MigrationArchiveDAL.archiveOriginalVault(sourceFolderURL: vault, libraryId: libraryId, in: archivesRoot)

        #expect(FileManager.default.fileExists(atPath: destination.appendingPathComponent("Note.md").path))
        #expect(MigrationArchiveDAL.listArchives(libraryId: libraryId, in: archivesRoot).count == 1)
    }

}
