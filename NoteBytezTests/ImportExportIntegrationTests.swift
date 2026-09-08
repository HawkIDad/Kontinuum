// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportExportIntegrationTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

/// Journey 1 end-to-end: scan a folder of real `.md` files → confirm import (with its
/// auto-snapshot) → spot-check the resulting library → export it back out → verify round-trip
/// fidelity. Mirrors UIUX/04-InteractionDesign.md's Journey 1 flowchart.
struct ImportExportIntegrationTests {

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

    private func write(_ content: String, to relativePath: String, in rootURL: URL) {
        let fileURL = rootURL.appendingPathComponent(relativePath)
        try? FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? content.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    @Test func journeyOneImportSpotCheckExportRoundTrip() throws {
        // A[S1] -> B[Select folder]: a small vault, matching the wireframe's example files.
        let vault = makeTempDirectory()
        write("- Stand-up notes: shipped [[Sync Log]] fixes\n- [ ] Review PR from Dana #standup", to: "Journal/2026-08-01.md", in: vault)
        write("# Sync Log\n\nFixed the reconnect race condition.", to: "Projects/Sync Log.md", in: vault)

        // B -> C[S2: Import Scan and Confirm summary]
        let backupDirectory = makeTempDirectory()
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Imported Vault", in: context)
        let libraryId = try #require(library.libraryId)

        let viewModel = ImportViewModel(library: library, folderURL: vault, modelContext: context)
        #expect(viewModel.noteCount == 2)
        #expect(viewModel.linkCount == 1)
        #expect(viewModel.taskCount == 1)

        // C -->|Confirm import| D[Auto snapshot created] --> E[Import runs]
        BackupDAL.createSnapshot(cause: .automatic, in: context, directory: backupDirectory)
        ImportDAL.importFiles(viewModel.files, libraryId: libraryId, in: context)

        // G[User opens S4 to spot-check] -> H{Links and tasks intact?}
        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(documents.count == 2)

        let journalEntry = try #require(documents.first { $0.title == "2026-08-01" })
        #expect(journalEntry.content?.contains("[[Sync Log]]") == true)
        #expect(journalEntry.content?.contains("- [ ] Review PR from Dana #standup") == true)

        let journalId = try #require(journalEntry.documentId)
        let journalTasks = TaskDAL.fetchActive(documentId: journalId, in: context)
        #expect(journalTasks.count == 1)
        #expect(journalTasks.first?.isDone == false)

        let syncLogDocument = try #require(documents.first { $0.title == "Sync Log" })
        let syncLogId = try #require(syncLogDocument.documentId)

        // The wikilink from the journal entry resolves as a backlink on "Sync Log" — proving
        // import needed no separate backlink-building step.
        let backlinks = BacklinkDAL.findBacklinks(to: "Sync Log", excluding: syncLogId, libraryId: libraryId, in: context)
        #expect(backlinks.count == 1)
        #expect(backlinks.first?.sourceDocument.documentId == journalId)

        // H -->|Yes| I[Per-note export - round-trip check]
        let exportDirectory = makeTempDirectory()
        let exportedCount = ExportDAL.exportLibrary(libraryId: libraryId, to: exportDirectory, in: context)
        #expect(exportedCount == 2)

        let exportedJournal = try String(contentsOf: exportDirectory.appendingPathComponent("2026-08-01.md"), encoding: .utf8)
        #expect(exportedJournal == journalEntry.content)

        let exportedSyncLog = try String(contentsOf: exportDirectory.appendingPathComponent("Sync Log.md"), encoding: .utf8)
        #expect(exportedSyncLog == syncLogDocument.content)
    }

    @Test func aBadImportCanBeUndoneFromItsAutoSnapshot() throws {
        // Existing library with a note already in it, before the import happens.
        let backupDirectory = makeTempDirectory()
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Existing Library", in: context)
        let libraryId = try #require(library.libraryId)
        _ = DocumentDAL.create(title: "Pre-existing Note", content: "Don't lose me.", libraryId: libraryId, in: context)

        // The auto-snapshot Phase 8 takes before every import.
        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: backupDirectory)

        // Import goes wrong (simulated here as an accidental soft-delete of everything).
        for document in DocumentDAL.fetchActive(libraryId: libraryId, in: context) {
            DocumentDAL.softDelete(document, in: context)
        }
        #expect(DocumentDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)

        // H -->|No, looks wrong| J[S12: Restore from backup]
        BackupDAL.restore(snapshot, in: context)

        let restored = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(restored.count == 1)
        #expect(restored.first?.title == "Pre-existing Note")
        #expect(restored.first?.content == "Don't lose me.")
    }

    /// A Kontinuum-exported vault re-imported elsewhere (or into a fresh library) should
    /// recreate the same Notebook membership by exact name — the whole point of the
    /// `notebooks:` frontmatter field over the write-only synthetic tag.
    @Test func notebookMembershipRoundTripsThroughExportAndReimport() throws {
        let sourceContext = try makeContext()
        let sourceLibrary = LibraryDAL.create(name: "Source", in: sourceContext)
        let sourceLibraryId = try #require(sourceLibrary.libraryId)
        let document = DocumentDAL.create(title: "Elena Voss", content: "A wandering engineer.", libraryId: sourceLibraryId, in: sourceContext)
        let notebook = NotebookDAL.create(name: "App Onboarding Revamp", libraryId: sourceLibraryId, in: sourceContext)
        NotebookDAL.attach(documentId: try #require(document.documentId), notebookId: try #require(notebook.notebookId), libraryId: sourceLibraryId, in: sourceContext)

        let exportDirectory = makeTempDirectory()
        ExportDAL.exportLibrary(libraryId: sourceLibraryId, to: exportDirectory, in: sourceContext)

        // Re-imported into a completely separate library/context, as if opened fresh elsewhere.
        let targetContext = try makeContext()
        let targetLibrary = LibraryDAL.create(name: "Reimported", in: targetContext)
        let targetLibraryId = try #require(targetLibrary.libraryId)
        let summaries = ImportScanner.scan(folderURL: exportDirectory)
        #expect(summaries.first?.notebookNames == ["App Onboarding Revamp"])

        ImportDAL.importFiles(summaries, libraryId: targetLibraryId, in: targetContext)

        let reimportedDocument = try #require(DocumentDAL.fetchActive(libraryId: targetLibraryId, in: targetContext).first)
        let reimportedNotebooks = NotebookDAL.fetchNotebooks(for: try #require(reimportedDocument.documentId), in: targetContext)
        #expect(reimportedNotebooks.map { $0.name } == ["App Onboarding Revamp"])
    }

}
