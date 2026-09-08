// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BackupDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct BackupDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self, DocumentNotebook.self, TaskItem.self, Property.self, DocumentProperty.self, TemplateGroup.self, NoteTemplate.self, NotebookTemplateGroup.self, JournalTemplateGroup.self, SavedView.self, Attachment.self, CanvasBoard.self, CanvasCard.self, CanvasConnector.self, Plugin.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func makeTempDirectory() -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @Test func listSnapshotsOnEmptyDirectoryReturnsEmptyList() {
        let directory = makeTempDirectory()
        #expect(BackupDAL.listSnapshots(in: directory).isEmpty)
    }

    @Test func createSnapshotCapturesActiveLibraries() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        _ = LibraryDAL.create(name: "Personal", in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        #expect(snapshot.cause == .manual)
        #expect(snapshot.libraries.count == 1)
        #expect(snapshot.libraries.first?.name == "Personal")

        let listed = BackupDAL.listSnapshots(in: directory)
        #expect(listed.count == 1)
        #expect(listed.first?.snapshotId == snapshot.snapshotId)
    }

    @Test func restoreReinsertsLibraryRemovedFromContext() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Work", in: context)
        let libraryId = library.libraryId

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        LibraryDAL.softDelete(library, in: context)
        #expect(LibraryDAL.fetchActive(in: context).isEmpty)

        BackupDAL.restore(snapshot, in: context)

        let restoredLibraries = LibraryDAL.fetchActive(in: context)
        #expect(restoredLibraries.count == 1)
        #expect(restoredLibraries.first?.libraryId == libraryId)
    }

    @Test func restoreUpdatesExistingLibraryInPlace() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Original", in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        library.name = "Changed"

        BackupDAL.restore(snapshot, in: context)

        #expect(library.name == "Original")
    }

    @Test func createSnapshotCapturesDocumentsBlocksTagsAndTasks() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        _ = DocumentDAL.create(title: "Note", content: "#roadmap\n- [ ] Ship it", libraryId: libraryId, in: context)
        let documentId = try #require(DocumentDAL.fetchActive(libraryId: libraryId, in: context).first?.documentId)
        TagDAL.syncTags(for: documentId, content: "#roadmap\n- [ ] Ship it", libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        #expect(snapshot.documents.count == 1)
        #expect(snapshot.blocks.count == 1)
        #expect(snapshot.tags.count == 1)
        #expect(snapshot.documentTags.count == 1)
        #expect(snapshot.taskItems.count == 1)
    }

    /// The scenario this exists for: a bad import corrupts the library's existing notes, and
    /// restoring the pre-import auto-snapshot needs to bring the notes back, not just the
    /// (empty) `Library` row.
    @Test func restoreReinsertsADocumentDeletedAfterTheSnapshot() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Note", content: "Original content", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        DocumentDAL.softDelete(document, in: context)
        #expect(DocumentDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)

        BackupDAL.restore(snapshot, in: context)

        let restoredDocuments = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(restoredDocuments.count == 1)
        #expect(restoredDocuments.first?.documentId == documentId)
        #expect(restoredDocuments.first?.content == "Original content")
    }

    @Test func createSnapshotCapturesNotebooksAndDocumentNotebooks() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Note", content: "content", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let notebook = NotebookDAL.create(name: "Book Series", libraryId: libraryId, in: context)
        NotebookDAL.attach(documentId: documentId, notebookId: try #require(notebook.notebookId), libraryId: libraryId, in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        #expect(snapshot.notebooks.count == 1)
        #expect(snapshot.notebooks.first?.name == "Book Series")
        #expect(snapshot.documentNotebooks.count == 1)
    }

    @Test func restoreReinsertsANotebookAndItsMembershipDeletedAfterTheSnapshot() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Note", content: "content", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let notebook = NotebookDAL.create(name: "Book Series", libraryId: libraryId, in: context)
        let notebookId = try #require(notebook.notebookId)
        NotebookDAL.attach(documentId: documentId, notebookId: notebookId, libraryId: libraryId, in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        NotebookDAL.softDelete(notebook, in: context)
        NotebookDAL.detach(documentId: documentId, notebookId: notebookId, in: context)
        #expect(NotebookDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)
        #expect(NotebookDAL.fetchNotebooks(for: documentId, in: context).isEmpty)

        BackupDAL.restore(snapshot, in: context)

        let restoredNotebooks = NotebookDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(restoredNotebooks.count == 1)
        #expect(restoredNotebooks.first?.notebookId == notebookId)
        #expect(NotebookDAL.fetchNotebooks(for: documentId, in: context).count == 1)
    }

    @Test func restoreOverwritesADocumentEditedAfterTheSnapshot() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Note", content: "Original content", libraryId: libraryId, in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        DocumentDAL.updateContent(document, content: "Corrupted by a bad import", in: context)

        BackupDAL.restore(snapshot, in: context)

        #expect(document.content == "Original content")
    }

    @Test func createSnapshotCapturesPropertiesAndDocumentProperties() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Elyra Voss", content: "---\nSpecies: Kethran\n---\n", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        PropertyDAL.syncProperties(for: documentId, content: try #require(document.content), libraryId: libraryId, in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        #expect(snapshot.properties.count == 1)
        #expect(snapshot.properties.first?.name == "Species")
        #expect(snapshot.documentProperties.count == 1)
        #expect(snapshot.documentProperties.first?.value == "Kethran")
    }

    @Test func restoreReinsertsAPropertyAndItsValueDeletedAfterTheSnapshot() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Elyra Voss", content: "---\nSpecies: Kethran\n---\n", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let property = PropertyDAL.findOrCreate(name: "Species", valueType: .text, libraryId: libraryId, in: context)
        let propertyId = try #require(property.propertyId)
        PropertyDAL.setValue(key: "Species", value: "Kethran", valueType: .text, documentId: documentId, libraryId: libraryId, in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        PropertyDAL.delete(property, in: context)
        #expect(PropertyDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)
        #expect(PropertyDAL.fetchProperties(for: documentId, in: context).isEmpty)

        BackupDAL.restore(snapshot, in: context)

        let restoredProperties = PropertyDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(restoredProperties.count == 1)
        #expect(restoredProperties.first?.propertyId == propertyId)
        let restoredValues = PropertyDAL.fetchProperties(for: documentId, in: context)
        #expect(restoredValues.count == 1)
        #expect(restoredValues.first?.value == "Kethran")
    }

    @Test func createSnapshotCapturesTemplateGroupsAndTheirJoins() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        // LibraryDAL.create already seeded 3 starter groups (Phase 3) — start from a clean slate.
        for group in TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context) {
            TemplateDAL.deleteGroup(group, in: context)
        }
        let notebook = NotebookDAL.create(name: "Book Series", libraryId: libraryId, in: context)
        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let groupId = try #require(group.templateGroupId)
        TemplateDAL.createTemplate(name: "Character", templateGroupId: groupId, libraryId: libraryId, in: context)
        TemplateDAL.attachToNotebook(templateGroupId: groupId, notebookId: try #require(notebook.notebookId), libraryId: libraryId, in: context)
        TemplateDAL.attachToJournal(templateGroupId: groupId, libraryId: libraryId, in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        #expect(snapshot.templateGroups.count == 1)
        #expect(snapshot.templateGroups.first?.name == "Fiction Writing")
        #expect(snapshot.noteTemplates.count == 1)
        #expect(snapshot.notebookTemplateGroups.count == 1)
        #expect(snapshot.journalTemplateGroups.count == 1)
    }

    @Test func restoreReinsertsATemplateGroupAndItsTemplateDeletedAfterTheSnapshot() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        for existingGroup in TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context) {
            TemplateDAL.deleteGroup(existingGroup, in: context)
        }
        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let groupId = try #require(group.templateGroupId)
        let template = TemplateDAL.createTemplate(name: "Character", templateGroupId: groupId, libraryId: libraryId, fields: [
            NoteTemplateField(name: "Species", valueType: .text, defaultValue: "Kethran")
        ], bodyTemplate: "# Character\n\n## Backstory", in: context)
        let templateId = try #require(template.noteTemplateId)

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        TemplateDAL.deleteGroup(group, in: context)
        #expect(TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context).isEmpty)

        BackupDAL.restore(snapshot, in: context)

        let restoredGroups = TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context)
        #expect(restoredGroups.count == 1)
        #expect(restoredGroups.first?.templateGroupId == groupId)
        let restoredTemplates = TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: context)
        #expect(restoredTemplates.first?.noteTemplateId == templateId)
        #expect(restoredTemplates.first?.fields.first?.name == "Species")
        #expect(restoredTemplates.first?.bodyTemplate == "# Character\n\n## Backstory")
    }

    @Test func createSnapshotCapturesSavedViews() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        SavedViewDAL.createSearchView(name: "Act 2 Antagonists", definition: SavedSearchDefinition(query: "#act2", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        #expect(snapshot.savedViews.count == 1)
        #expect(snapshot.savedViews.first?.name == "Act 2 Antagonists")
        #expect(snapshot.savedViews.first?.searchDefinition?.query == "#act2")
    }

    @Test func restoreReinsertsASavedViewDeletedAfterTheSnapshot() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let savedView = SavedViewDAL.createSearchView(name: "Act 2 Antagonists", definition: SavedSearchDefinition(query: "#act2", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)
        let savedViewId = try #require(savedView.savedViewId)

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        SavedViewDAL.delete(savedView, in: context)
        #expect(SavedViewDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)

        BackupDAL.restore(snapshot, in: context)

        let restored = SavedViewDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(restored.count == 1)
        #expect(restored.first?.savedViewId == savedViewId)
        #expect(restored.first?.searchDefinition?.query == "#act2")
    }

    @Test func createSnapshotCapturesAttachments() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Location Reference", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let attachment = Attachment(documentId: documentId, fileName: "harbor.jpg", relativePath: "AttachmentStore/\(documentId.uuidString)/1-harbor.jpg", mimeType: "image/jpeg")
        context.insert(attachment)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        #expect(snapshot.attachments.count == 1)
        #expect(snapshot.attachments.first?.fileName == "harbor.jpg")
    }

    @Test func restoreReinsertsAnAttachmentDeletedAfterTheSnapshot() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let document = DocumentDAL.create(title: "Location Reference", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let attachment = Attachment(documentId: documentId, fileName: "harbor.jpg", relativePath: "AttachmentStore/\(documentId.uuidString)/1-harbor.jpg", mimeType: "image/jpeg")
        context.insert(attachment)
        let attachmentId = try #require(attachment.attachmentId)

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        AttachmentDAL.remove(attachment, in: context)
        #expect(AttachmentDAL.fetchActive(documentId: documentId, in: context).isEmpty)

        BackupDAL.restore(snapshot, in: context)

        let restored = AttachmentDAL.fetchActive(documentId: documentId, in: context)
        #expect(restored.count == 1)
        #expect(restored.first?.attachmentId == attachmentId)
        #expect(restored.first?.relativePath == attachment.relativePath)
    }

    @Test func createSnapshotCapturesCanvasBoardsCardsAndConnectors() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let board = CanvasDAL.createBoard(name: "Mystery Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)
        let cardA = CanvasDAL.addWebCard(url: "https://a.example.com", boardId: boardId, x: 0, y: 0, in: context)
        let cardB = CanvasDAL.addWebCard(url: "https://b.example.com", boardId: boardId, x: 100, y: 0, in: context)
        CanvasDAL.addConnector(from: try #require(cardA.canvasCardId), to: try #require(cardB.canvasCardId), boardId: boardId, label: "reveals", in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        #expect(snapshot.canvasBoards.count == 1)
        #expect(snapshot.canvasBoards.first?.name == "Mystery Board")
        #expect(snapshot.canvasCards.count == 2)
        #expect(snapshot.canvasConnectors.count == 1)
        #expect(snapshot.canvasConnectors.first?.label == "reveals")
    }

    @Test func restoreReinsertsACanvasBoardDeletedAfterTheSnapshot() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let board = CanvasDAL.createBoard(name: "Mystery Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)
        let card = CanvasDAL.addWebCard(url: "https://a.example.com", boardId: boardId, x: 0, y: 0, in: context)
        let cardId = try #require(card.canvasCardId)

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        CanvasDAL.deleteBoard(board, in: context)
        #expect(CanvasDAL.fetchActiveBoards(libraryId: libraryId, in: context).isEmpty)

        BackupDAL.restore(snapshot, in: context)

        let restoredBoards = CanvasDAL.fetchActiveBoards(libraryId: libraryId, in: context)
        #expect(restoredBoards.count == 1)
        #expect(restoredBoards.first?.canvasBoardId == boardId)

        let restoredCards = CanvasDAL.fetchActiveCards(boardId: boardId, in: context)
        #expect(restoredCards.count == 1)
        #expect(restoredCards.first?.canvasCardId == cardId)
    }

    @Test func createSnapshotCapturesPlugins() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        PluginDAL.install(name: "Word Count", entryScript: "noteBytez.addCommand('x');", permissions: [.readLibrary], libraryId: libraryId, in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)

        #expect(snapshot.plugins.count == 1)
        #expect(snapshot.plugins.first?.name == "Word Count")
        #expect(snapshot.plugins.first?.grantedPermissions == [.readLibrary])
    }

    @Test func restoreReinsertsAPluginDeletedAfterTheSnapshot() throws {
        let context = try makeContext()
        let directory = makeTempDirectory()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)
        let plugin = PluginDAL.install(name: "Word Count", entryScript: "noteBytez.addCommand('x');", permissions: [.readLibrary, .writeCurrentNote], libraryId: libraryId, in: context)
        let pluginId = try #require(plugin.pluginId)

        let snapshot = BackupDAL.createSnapshot(cause: .automatic, in: context, directory: directory)

        PluginDAL.uninstall(plugin, in: context)
        #expect(PluginDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)

        BackupDAL.restore(snapshot, in: context)

        let restored = PluginDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(restored.count == 1)
        #expect(restored.first?.pluginId == pluginId)
        #expect(restored.first?.grantedPermissions == [.readLibrary, .writeCurrentNote])
    }

}
