// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncMappingTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import CloudKit
import Foundation
@testable import Kontinuum

/// Covers everything about Phase 12's sync layer that's verifiable without a live, signed-in
/// iCloud account: zone-ID determinism, model<->CKRecord field mapping, library-reference
/// parenting, and record-type dispatch. Actual network sync (zone/record round-trips against
/// real CloudKit, conflict delivery) needs a device+account and isn't exercised here.
struct SyncMappingTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self, DocumentNotebook.self, TaskItem.self, Property.self, DocumentProperty.self, TemplateGroup.self, NoteTemplate.self, NotebookTemplateGroup.self, JournalTemplateGroup.self, SavedView.self, Attachment.self, CanvasBoard.self, CanvasCard.self, CanvasConnector.self, Plugin.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - Zone ID

    @Test func libraryZoneIDIsDeterministic() {
        let libraryId = UUID()
        #expect(CKRecordZone.ID.library(libraryId) == CKRecordZone.ID.library(libraryId))
    }

    @Test func libraryZoneIDDiffersAcrossLibraries() {
        #expect(CKRecordZone.ID.library(UUID()) != CKRecordZone.ID.library(UUID()))
    }

    // MARK: - resolvedLibraryId

    @Test func documentResolvesItsOwnLibraryId() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "", libraryId: libraryId, in: context)
        #expect(document.resolvedLibraryId(in: context) == libraryId)
    }

    @Test func blockResolvesLibraryIdViaItsOwningDocument() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "First block", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let block = try #require(BlockDAL.fetchActive(documentId: documentId, in: context).first)

        #expect(block.resolvedLibraryId(in: context) == libraryId)
    }

    @Test func libraryResolvesToItself() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)
        #expect(library.resolvedLibraryId(in: context) == library.libraryId)
    }

    // MARK: - makeCKRecord: identity, zone, parenting

    @Test func makeCKRecordUsesModelIdAsRecordName() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let record = try #require(document.makeCKRecord(in: context))

        #expect(record.recordID.recordName == documentId.uuidString)
        #expect(record.recordID.zoneID == .library(libraryId))
        #expect(record.recordType == Document.ckRecordType)
    }

    @Test func makeCKRecordSetsLibraryReferenceForNonLibraryRecords() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "", libraryId: libraryId, in: context)

        let record = try #require(document.makeCKRecord(in: context))
        let reference = try #require(record["library"] as? CKRecord.Reference)

        #expect(reference.recordID == .record(syncId: libraryId, zoneID: .library(libraryId)))
    }

    @Test func makeCKRecordOmitsLibraryReferenceForTheLibraryRecordItself() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)

        let record = try #require(library.makeCKRecord(in: context))

        #expect(record["library"] == nil)
    }

    // MARK: - Field round-trips (write -> fresh record -> read back into a blank instance)

    @Test func documentFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let original = DocumentDAL.create(title: "Roadmap", content: "See [[Other]]", libraryId: libraryId, in: context)
        original.isJournalEntry = true
        original.journalDate = Date(timeIntervalSince1970: 1_000_000)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = Document(title: "", content: "", libraryId: UUID())
        copy.readFields(from: record)

        #expect(copy.title == original.title)
        #expect(copy.content == original.content)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.isJournalEntry == original.isJournalEntry)
        #expect(copy.journalDate == original.journalDate)
        #expect(copy.isActive == original.isActive)
    }

    @Test func blockFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "# Heading\n\nOnly block", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let original = try #require(BlockDAL.fetchActive(documentId: documentId, in: context).first { $0.content == "Only block" })

        let record = try #require(original.makeCKRecord(in: context))
        let copy = Block(content: "", anchor: "", sortOrder: -1, documentId: UUID())
        copy.readFields(from: record)

        #expect(copy.content == original.content)
        #expect(copy.anchor == original.anchor)
        #expect(copy.sortOrder == original.sortOrder)
        #expect(copy.documentId == original.documentId)
        #expect(copy.headingPath == original.headingPath)
        #expect(original.headingPath == "Heading")
    }

    @Test func taskItemFieldsRoundTripIncludingUnusedMVPFields() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let original = TaskItem(content: "Buy milk", isDone: true, documentId: UUID(), blockId: UUID(), libraryId: libraryId)
        original.dueDate = Date(timeIntervalSince1970: 2_000_000)
        original.priority = 1
        original.recurrenceRule = "FREQ=WEEKLY"
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = TaskItem(content: "", isDone: false, documentId: UUID(), blockId: UUID(), libraryId: UUID())
        copy.readFields(from: record)

        #expect(copy.content == original.content)
        #expect(copy.isDone == original.isDone)
        #expect(copy.documentId == original.documentId)
        #expect(copy.blockId == original.blockId)
        #expect(copy.dueDate == original.dueDate)
        #expect(copy.priority == original.priority)
        #expect(copy.recurrenceRule == original.recurrenceRule)
    }

    @Test func documentTagFieldsRoundTrip() throws {
        let context = try makeContext()
        let original = DocumentTag(documentId: UUID(), tagId: UUID(), libraryId: UUID())
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = DocumentTag(documentId: UUID(), tagId: UUID(), libraryId: UUID())
        copy.readFields(from: record)

        #expect(copy.documentId == original.documentId)
        #expect(copy.tagId == original.tagId)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.isActive == original.isActive)
    }

    @Test func documentNotebookFieldsRoundTrip() throws {
        let context = try makeContext()
        let original = DocumentNotebook(documentId: UUID(), notebookId: UUID(), libraryId: UUID())
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = DocumentNotebook(documentId: UUID(), notebookId: UUID(), libraryId: UUID())
        copy.readFields(from: record)

        #expect(copy.documentId == original.documentId)
        #expect(copy.notebookId == original.notebookId)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.isActive == original.isActive)
    }

    @Test func propertyFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let original = Property(name: "Species", valueType: .text, libraryId: libraryId)
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = Property(name: "", valueType: .text, libraryId: UUID())
        copy.readFields(from: record)

        #expect(copy.name == original.name)
        #expect(copy.valueType == original.valueType)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.isActive == original.isActive)
    }

    @Test func documentPropertyFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let original = DocumentProperty(documentId: UUID(), propertyId: UUID(), libraryId: libraryId, value: "Kethran", valueType: .text)
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = DocumentProperty(documentId: UUID(), propertyId: UUID(), libraryId: UUID(), value: "", valueType: .text)
        copy.readFields(from: record)

        #expect(copy.documentId == original.documentId)
        #expect(copy.propertyId == original.propertyId)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.value == original.value)
        #expect(copy.valueType == original.valueType)
        #expect(copy.isActive == original.isActive)
    }

    @Test func templateGroupFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let original = TemplateGroup(name: "Fiction Writing", libraryId: libraryId)
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = TemplateGroup(name: "", libraryId: UUID())
        copy.readFields(from: record)

        #expect(copy.name == original.name)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.isActive == original.isActive)
    }

    @Test func noteTemplateFieldsRoundTripIncludingFieldsJSON() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let original = NoteTemplate(name: "Character", templateGroupId: UUID(), libraryId: libraryId, fields: [
            NoteTemplateField(name: "Species", valueType: .text, defaultValue: "Kethran")
        ], bodyTemplate: "# Character\n\n## Backstory\n\n- [ ] Fill in")
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = NoteTemplate(name: "", templateGroupId: UUID(), libraryId: UUID())
        copy.readFields(from: record)

        #expect(copy.name == original.name)
        #expect(copy.templateGroupId == original.templateGroupId)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.fields == original.fields)
        #expect(copy.bodyTemplate == original.bodyTemplate)
    }

    @Test func notebookTemplateGroupFieldsRoundTrip() throws {
        let context = try makeContext()
        let original = NotebookTemplateGroup(notebookId: UUID(), templateGroupId: UUID(), libraryId: UUID())
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = NotebookTemplateGroup(notebookId: UUID(), templateGroupId: UUID(), libraryId: UUID())
        copy.readFields(from: record)

        #expect(copy.notebookId == original.notebookId)
        #expect(copy.templateGroupId == original.templateGroupId)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.isActive == original.isActive)
    }

    @Test func journalTemplateGroupFieldsRoundTrip() throws {
        let context = try makeContext()
        let original = JournalTemplateGroup(libraryId: UUID(), templateGroupId: UUID())
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = JournalTemplateGroup(libraryId: UUID(), templateGroupId: UUID())
        copy.readFields(from: record)

        #expect(copy.libraryId == original.libraryId)
        #expect(copy.templateGroupId == original.templateGroupId)
        #expect(copy.isActive == original.isActive)
    }

    @Test func savedViewFieldsRoundTripIncludingDefinitionJSON() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let original = SavedView(name: "Act 2 Antagonists", libraryId: libraryId, queryType: .search, sortOrder: 3)
        original.searchDefinition = SavedSearchDefinition(query: "#character AND #act2", scope: "Content", isAdvancedMode: true)
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = SavedView(name: "", libraryId: UUID(), queryType: .search, sortOrder: 0)
        copy.readFields(from: record)

        #expect(copy.name == original.name)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.queryType == original.queryType)
        #expect(copy.sortOrder == original.sortOrder)
        #expect(copy.searchDefinition == original.searchDefinition)
    }

    @Test func attachmentFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Location Reference", content: "", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let original = Attachment(documentId: documentId, fileName: "harbor.jpg", relativePath: "AttachmentStore/\(documentId.uuidString)/1-harbor.jpg", mimeType: "image/jpeg")
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = Attachment(documentId: UUID(), fileName: "", relativePath: "", mimeType: "")
        copy.readFields(from: record)

        #expect(copy.documentId == original.documentId)
        #expect(copy.fileName == original.fileName)
        #expect(copy.relativePath == original.relativePath)
        #expect(copy.mimeType == original.mimeType)
        #expect(copy.isActive == original.isActive)
    }

    @Test func canvasBoardFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let original = CanvasBoard(name: "Mystery Board", libraryId: libraryId)
        original.boundDocumentId = UUID()
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = CanvasBoard(name: "", libraryId: UUID())
        copy.readFields(from: record)

        #expect(copy.name == original.name)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.boundDocumentId == original.boundDocumentId)
        #expect(copy.isActive == original.isActive)
    }

    @Test func canvasBoardBoundDocumentIdDefaultsNilAndRoundTrips() throws {
        let context = try makeContext()
        let unbound = CanvasBoard(name: "Ordinary Board", libraryId: UUID())
        context.insert(unbound)

        #expect(unbound.boundDocumentId == nil)

        let record = try #require(unbound.makeCKRecord(in: context))
        let copy = CanvasBoard(name: "", libraryId: UUID())
        copy.boundDocumentId = UUID()
        copy.readFields(from: record)

        #expect(copy.boundDocumentId == nil)
    }

    @Test func canvasCardFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)
        let original = CanvasCard(canvasBoardId: boardId, cardType: .web, positionX: 10, positionY: 20, width: 240, height: 140)
        original.url = "https://example.com"
        original.color = "#FF0000"
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = CanvasCard(canvasBoardId: UUID(), cardType: .note, positionX: 0, positionY: 0, width: 0, height: 0)
        copy.readFields(from: record)

        #expect(copy.canvasBoardId == original.canvasBoardId)
        #expect(copy.cardType == original.cardType)
        #expect(copy.url == original.url)
        #expect(copy.color == original.color)
        #expect(copy.positionX == original.positionX)
        #expect(copy.positionY == original.positionY)
        #expect(copy.width == original.width)
        #expect(copy.height == original.height)
        #expect(copy.isActive == original.isActive)
    }

    @Test func canvasConnectorFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let board = CanvasDAL.createBoard(name: "Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)
        let original = CanvasConnector(canvasBoardId: boardId, fromCardId: UUID(), toCardId: UUID())
        original.fromSide = "right"
        original.toSide = "left"
        original.color = "#00FF00"
        original.label = "reveals"
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = CanvasConnector(canvasBoardId: UUID(), fromCardId: UUID(), toCardId: UUID())
        copy.readFields(from: record)

        #expect(copy.canvasBoardId == original.canvasBoardId)
        #expect(copy.fromCardId == original.fromCardId)
        #expect(copy.toCardId == original.toCardId)
        #expect(copy.fromSide == original.fromSide)
        #expect(copy.toSide == original.toSide)
        #expect(copy.color == original.color)
        #expect(copy.label == original.label)
        #expect(copy.isActive == original.isActive)
    }

    @Test func pluginFieldsRoundTrip() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let original = Plugin(name: "Word Count", libraryId: libraryId, entryScript: "noteBytez.addCommand('Insert Word Count');", permissions: [.readLibrary, .writeCurrentNote])
        context.insert(original)

        let record = try #require(original.makeCKRecord(in: context))
        let copy = Plugin(name: "", libraryId: UUID(), entryScript: "", permissions: [])
        copy.readFields(from: record)

        #expect(copy.name == original.name)
        #expect(copy.libraryId == original.libraryId)
        #expect(copy.entryScript == original.entryScript)
        #expect(copy.grantedPermissions == original.grantedPermissions)
        #expect(copy.isEnabled == original.isEnabled)
        #expect(copy.isActive == original.isActive)
    }

    // MARK: - Record-type dispatch (SyncRecordFactory)

    @Test func buildRecordFindsTheRightModelAcrossAllTwentyTables() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let notebook = NotebookDAL.create(name: "Projects", libraryId: libraryId, in: context)
        let tag = TagDAL.findOrCreate(name: "work", libraryId: libraryId, in: context)
        let document = DocumentDAL.create(title: "Note", content: "Only block", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let block = try #require(BlockDAL.fetchActive(documentId: documentId, in: context).first)
        let task = TaskItem(content: "Buy milk", isDone: false, documentId: documentId, blockId: try #require(block.blockId), libraryId: libraryId)
        context.insert(task)
        let documentTag = DocumentTag(documentId: documentId, tagId: try #require(tag.tagId), libraryId: libraryId)
        context.insert(documentTag)
        let documentNotebook = DocumentNotebook(documentId: documentId, notebookId: try #require(notebook.notebookId), libraryId: libraryId)
        context.insert(documentNotebook)
        let property = PropertyDAL.findOrCreate(name: "Species", valueType: .text, libraryId: libraryId, in: context)
        let documentProperty = PropertyDAL.setValue(key: "Species", value: "Kethran", valueType: .text, documentId: documentId, libraryId: libraryId, in: context)
        let templateGroup = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let templateGroupId = try #require(templateGroup.templateGroupId)
        let noteTemplate = TemplateDAL.createTemplate(name: "Character", templateGroupId: templateGroupId, libraryId: libraryId, in: context)
        let notebookTemplateGroup = TemplateDAL.attachToNotebook(templateGroupId: templateGroupId, notebookId: try #require(notebook.notebookId), libraryId: libraryId, in: context)
        let journalTemplateGroup = TemplateDAL.attachToJournal(templateGroupId: templateGroupId, libraryId: libraryId, in: context)
        let savedView = SavedViewDAL.createSearchView(name: "Act 2 Antagonists", definition: SavedSearchDefinition(query: "#act2", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)
        let attachment = Attachment(documentId: documentId, fileName: "harbor.jpg", relativePath: "AttachmentStore/\(documentId.uuidString)/1-harbor.jpg", mimeType: "image/jpeg")
        context.insert(attachment)
        let board = CanvasDAL.createBoard(name: "Mystery Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)
        let card = CanvasDAL.addWebCard(url: "https://example.com", boardId: boardId, x: 0, y: 0, in: context)
        let connector = CanvasDAL.addConnector(from: try #require(card.canvasCardId), to: try #require(card.canvasCardId), boardId: boardId, in: context)
        let plugin = PluginDAL.install(name: "Word Count", entryScript: "noteBytez.addCommand('x');", permissions: [.readLibrary], libraryId: libraryId, in: context)

        for (syncId, expectedType) in [
            (library.libraryId, Library.ckRecordType),
            (notebook.notebookId, Notebook.ckRecordType),
            (tag.tagId, Tag.ckRecordType),
            (document.documentId, Document.ckRecordType),
            (block.blockId, Block.ckRecordType),
            (task.taskItemId, TaskItem.ckRecordType),
            (documentTag.documentTagId, DocumentTag.ckRecordType),
            (documentNotebook.documentNotebookId, DocumentNotebook.ckRecordType),
            (property.propertyId, Property.ckRecordType),
            (documentProperty.documentPropertyId, DocumentProperty.ckRecordType),
            (templateGroup.templateGroupId, TemplateGroup.ckRecordType),
            (noteTemplate.noteTemplateId, NoteTemplate.ckRecordType),
            (notebookTemplateGroup.notebookTemplateGroupId, NotebookTemplateGroup.ckRecordType),
            (journalTemplateGroup.journalTemplateGroupId, JournalTemplateGroup.ckRecordType),
            (savedView.savedViewId, SavedView.ckRecordType),
            (attachment.attachmentId, Attachment.ckRecordType),
            (board.canvasBoardId, CanvasBoard.ckRecordType),
            (card.canvasCardId, CanvasCard.ckRecordType),
            (connector.canvasConnectorId, CanvasConnector.ckRecordType),
            (plugin.pluginId, Plugin.ckRecordType)
        ] {
            let id = try #require(syncId)
            let record = SyncRecordFactory.buildRecord(for: .record(syncId: id, zoneID: .library(libraryId)), in: context)
            #expect(record?.recordType == expectedType)
        }
    }

    @Test func buildRecordReturnsNilForAnUnknownId() throws {
        let context = try makeContext()
        let record = SyncRecordFactory.buildRecord(for: .record(syncId: UUID(), zoneID: .library(UUID())), in: context)
        #expect(record == nil)
    }

    // MARK: - upsert (incoming records)

    @Test func upsertCreatesANewDocumentWhenNoneExistsLocally() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let remoteId = UUID()
        let record = CKRecord(recordType: Document.ckRecordType, recordID: .record(syncId: remoteId, zoneID: .library(libraryId)))
        record["title"] = "From Another Device"
        record["content"] = "Synced content"
        record["libraryId"] = libraryId.uuidString
        record["isActive"] = true

        let upserted = try #require(Document.upsert(from: record, in: context))

        #expect(upserted.documentId == remoteId)
        #expect(upserted.title == "From Another Device")
        #expect(Document.fetch(syncId: remoteId, in: context) != nil)
    }

    @Test func upsertUpdatesAnExistingDocumentRatherThanDuplicating() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Original", content: "v1", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let record = CKRecord(recordType: Document.ckRecordType, recordID: .record(syncId: documentId, zoneID: .library(libraryId)))
        record["title"] = "Updated Elsewhere"
        record["content"] = "v2"
        record["libraryId"] = libraryId.uuidString
        record["isActive"] = true

        Document.upsert(from: record, in: context)

        let matches = DocumentDAL.fetchActive(libraryId: libraryId, in: context).filter { $0.documentId == documentId }
        #expect(matches.count == 1)
        #expect(matches.first?.title == "Updated Elsewhere")
    }

    // MARK: - applyIncoming / applyDeletion (SyncRecordFactory)

    @Test func applyIncomingDispatchesToTheRightModelAcrossAllTwentyTables() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let zoneID = CKRecordZone.ID.library(libraryId)

        func record(type: String, syncId: UUID, fields: [String: CKRecordValueProtocol]) -> CKRecord {
            let record = CKRecord(recordType: type, recordID: .record(syncId: syncId, zoneID: zoneID))
            for (key, value) in fields { record[key] = value }
            return record
        }

        let libraryRecord = record(type: Library.ckRecordType, syncId: libraryId, fields: ["name": "Mine", "isActive": true])
        let documentId = UUID()
        let documentRecord = record(type: Document.ckRecordType, syncId: documentId, fields: ["title": "Note", "content": "", "libraryId": libraryId.uuidString, "isActive": true])
        let blockRecord = record(type: Block.ckRecordType, syncId: UUID(), fields: ["content": "text", "anchor": "a1", "sortOrder": 0, "documentId": documentId.uuidString, "isActive": true])
        let tagRecord = record(type: Tag.ckRecordType, syncId: UUID(), fields: ["name": "work", "libraryId": libraryId.uuidString, "isActive": true])
        let notebookRecord = record(type: Notebook.ckRecordType, syncId: UUID(), fields: ["name": "Projects", "libraryId": libraryId.uuidString, "isActive": true])
        let taskRecord = record(type: TaskItem.ckRecordType, syncId: UUID(), fields: ["content": "Buy milk", "isDone": false, "documentId": documentId.uuidString, "libraryId": libraryId.uuidString, "isActive": true])
        let documentTagRecord = record(type: DocumentTag.ckRecordType, syncId: UUID(), fields: ["documentId": documentId.uuidString, "tagId": UUID().uuidString, "libraryId": libraryId.uuidString, "isActive": true])
        let documentNotebookRecord = record(type: DocumentNotebook.ckRecordType, syncId: UUID(), fields: ["documentId": documentId.uuidString, "notebookId": UUID().uuidString, "libraryId": libraryId.uuidString, "isActive": true])
        let propertyId = UUID()
        let propertyRecord = record(type: Property.ckRecordType, syncId: propertyId, fields: ["name": "Species", "valueType": PropertyValueType.text.rawValue, "libraryId": libraryId.uuidString, "isActive": true])
        let documentPropertyRecord = record(type: DocumentProperty.ckRecordType, syncId: UUID(), fields: ["documentId": documentId.uuidString, "propertyId": propertyId.uuidString, "libraryId": libraryId.uuidString, "value": "Kethran", "valueType": PropertyValueType.text.rawValue, "isActive": true])
        let templateGroupId = UUID()
        let templateGroupRecord = record(type: TemplateGroup.ckRecordType, syncId: templateGroupId, fields: ["name": "Fiction Writing", "libraryId": libraryId.uuidString, "isActive": true])
        let noteTemplateRecord = record(type: NoteTemplate.ckRecordType, syncId: UUID(), fields: ["name": "Character", "templateGroupId": templateGroupId.uuidString, "libraryId": libraryId.uuidString, "fieldsJSON": "[]", "isActive": true])
        let notebookTemplateGroupRecord = record(type: NotebookTemplateGroup.ckRecordType, syncId: UUID(), fields: ["notebookId": UUID().uuidString, "templateGroupId": templateGroupId.uuidString, "libraryId": libraryId.uuidString, "isActive": true])
        let journalTemplateGroupRecord = record(type: JournalTemplateGroup.ckRecordType, syncId: UUID(), fields: ["libraryId": libraryId.uuidString, "templateGroupId": templateGroupId.uuidString, "isActive": true])
        let savedViewRecord = record(type: SavedView.ckRecordType, syncId: UUID(), fields: ["name": "Act 2 Antagonists", "libraryId": libraryId.uuidString, "queryType": SavedViewQueryType.search.rawValue, "sortOrder": 0, "isActive": true])
        let attachmentRecord = record(type: Attachment.ckRecordType, syncId: UUID(), fields: ["documentId": documentId.uuidString, "fileName": "harbor.jpg", "relativePath": "AttachmentStore/\(documentId.uuidString)/1-harbor.jpg", "mimeType": "image/jpeg", "isActive": true])
        let boardId = UUID()
        let boardRecord = record(type: CanvasBoard.ckRecordType, syncId: boardId, fields: ["name": "Mystery Board", "libraryId": libraryId.uuidString, "isActive": true])
        let cardId = UUID()
        let cardRecord = record(type: CanvasCard.ckRecordType, syncId: cardId, fields: ["canvasBoardId": boardId.uuidString, "cardType": CanvasCardType.web.rawValue, "url": "https://example.com", "positionX": 0.0, "positionY": 0.0, "width": 240.0, "height": 140.0, "isActive": true])
        let connectorRecord = record(type: CanvasConnector.ckRecordType, syncId: UUID(), fields: ["canvasBoardId": boardId.uuidString, "fromCardId": cardId.uuidString, "toCardId": cardId.uuidString, "isActive": true])
        let pluginRecord = record(type: Plugin.ckRecordType, syncId: UUID(), fields: ["name": "Word Count", "libraryId": libraryId.uuidString, "entryScript": "noteBytez.addCommand('x');", "permissionsJSON": "[\"readLibrary\"]", "isEnabled": true, "isActive": true])

        for incoming in [libraryRecord, documentRecord, blockRecord, tagRecord, notebookRecord, taskRecord, documentTagRecord, documentNotebookRecord, propertyRecord, documentPropertyRecord, templateGroupRecord, noteTemplateRecord, notebookTemplateGroupRecord, journalTemplateGroupRecord, savedViewRecord, attachmentRecord, boardRecord, cardRecord, connectorRecord, pluginRecord] {
            SyncRecordFactory.applyIncoming(incoming, in: context)
        }

        #expect(Library.fetch(syncId: libraryId, in: context) != nil)
        #expect(Document.fetch(syncId: documentId, in: context) != nil)
        #expect(Block.fetch(syncId: try #require(UUID(uuidString: blockRecord.recordID.recordName)), in: context) != nil)
        #expect(Tag.fetch(syncId: try #require(UUID(uuidString: tagRecord.recordID.recordName)), in: context) != nil)
        #expect(Notebook.fetch(syncId: try #require(UUID(uuidString: notebookRecord.recordID.recordName)), in: context) != nil)
        #expect(TaskItem.fetch(syncId: try #require(UUID(uuidString: taskRecord.recordID.recordName)), in: context) != nil)
        #expect(DocumentTag.fetch(syncId: try #require(UUID(uuidString: documentTagRecord.recordID.recordName)), in: context) != nil)
        #expect(DocumentNotebook.fetch(syncId: try #require(UUID(uuidString: documentNotebookRecord.recordID.recordName)), in: context) != nil)
        #expect(Property.fetch(syncId: propertyId, in: context) != nil)
        #expect(DocumentProperty.fetch(syncId: try #require(UUID(uuidString: documentPropertyRecord.recordID.recordName)), in: context) != nil)
        #expect(TemplateGroup.fetch(syncId: templateGroupId, in: context) != nil)
        #expect(NoteTemplate.fetch(syncId: try #require(UUID(uuidString: noteTemplateRecord.recordID.recordName)), in: context) != nil)
        #expect(NotebookTemplateGroup.fetch(syncId: try #require(UUID(uuidString: notebookTemplateGroupRecord.recordID.recordName)), in: context) != nil)
        #expect(JournalTemplateGroup.fetch(syncId: try #require(UUID(uuidString: journalTemplateGroupRecord.recordID.recordName)), in: context) != nil)
        #expect(SavedView.fetch(syncId: try #require(UUID(uuidString: savedViewRecord.recordID.recordName)), in: context) != nil)
        #expect(Attachment.fetch(syncId: try #require(UUID(uuidString: attachmentRecord.recordID.recordName)), in: context) != nil)
        #expect(CanvasBoard.fetch(syncId: boardId, in: context) != nil)
        #expect(CanvasCard.fetch(syncId: cardId, in: context) != nil)
        #expect(CanvasConnector.fetch(syncId: try #require(UUID(uuidString: connectorRecord.recordID.recordName)), in: context) != nil)
        #expect(Plugin.fetch(syncId: try #require(UUID(uuidString: pluginRecord.recordID.recordName)), in: context) != nil)
    }

    @Test func applyIncomingIgnoresAnUnknownRecordType() throws {
        let context = try makeContext()
        let record = CKRecord(recordType: "SomethingElse", recordID: .record(syncId: UUID(), zoneID: .library(UUID())))
        SyncRecordFactory.applyIncoming(record, in: context)
        // No crash, and nothing to assert beyond "didn't dispatch anywhere" — covered by the default: break branch.
    }

    @Test func applyDeletionSoftDeletesTheRightModelAcrossAllTwentyTables() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let notebook = NotebookDAL.create(name: "Projects", libraryId: libraryId, in: context)
        let tag = TagDAL.findOrCreate(name: "work", libraryId: libraryId, in: context)
        let document = DocumentDAL.create(title: "Note", content: "Only block", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let block = try #require(BlockDAL.fetchActive(documentId: documentId, in: context).first)
        let task = TaskItem(content: "Buy milk", isDone: false, documentId: documentId, blockId: try #require(block.blockId), libraryId: libraryId)
        context.insert(task)
        let documentTag = DocumentTag(documentId: documentId, tagId: try #require(tag.tagId), libraryId: libraryId)
        context.insert(documentTag)
        let documentNotebook = DocumentNotebook(documentId: documentId, notebookId: try #require(notebook.notebookId), libraryId: libraryId)
        context.insert(documentNotebook)
        let property = PropertyDAL.findOrCreate(name: "Species", valueType: .text, libraryId: libraryId, in: context)
        let documentProperty = PropertyDAL.setValue(key: "Species", value: "Kethran", valueType: .text, documentId: documentId, libraryId: libraryId, in: context)
        let templateGroup = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let templateGroupId = try #require(templateGroup.templateGroupId)
        let noteTemplate = TemplateDAL.createTemplate(name: "Character", templateGroupId: templateGroupId, libraryId: libraryId, in: context)
        let notebookTemplateGroup = TemplateDAL.attachToNotebook(templateGroupId: templateGroupId, notebookId: try #require(notebook.notebookId), libraryId: libraryId, in: context)
        let journalTemplateGroup = TemplateDAL.attachToJournal(templateGroupId: templateGroupId, libraryId: libraryId, in: context)
        let savedView = SavedViewDAL.createSearchView(name: "Act 2 Antagonists", definition: SavedSearchDefinition(query: "#act2", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)
        let attachment = Attachment(documentId: documentId, fileName: "harbor.jpg", relativePath: "AttachmentStore/\(documentId.uuidString)/1-harbor.jpg", mimeType: "image/jpeg")
        context.insert(attachment)
        let board = CanvasDAL.createBoard(name: "Mystery Board", libraryId: libraryId, in: context)
        let boardId = try #require(board.canvasBoardId)
        let card = CanvasDAL.addWebCard(url: "https://example.com", boardId: boardId, x: 0, y: 0, in: context)
        let connector = CanvasDAL.addConnector(from: try #require(card.canvasCardId), to: try #require(card.canvasCardId), boardId: boardId, in: context)
        let plugin = PluginDAL.install(name: "Word Count", entryScript: "noteBytez.addCommand('x');", permissions: [.readLibrary], libraryId: libraryId, in: context)

        let zoneID = CKRecordZone.ID.library(libraryId)
        for (syncId, type) in [
            (library.libraryId, Library.ckRecordType),
            (notebook.notebookId, Notebook.ckRecordType),
            (tag.tagId, Tag.ckRecordType),
            (document.documentId, Document.ckRecordType),
            (block.blockId, Block.ckRecordType),
            (task.taskItemId, TaskItem.ckRecordType),
            (documentTag.documentTagId, DocumentTag.ckRecordType),
            (documentNotebook.documentNotebookId, DocumentNotebook.ckRecordType),
            (property.propertyId, Property.ckRecordType),
            (documentProperty.documentPropertyId, DocumentProperty.ckRecordType),
            (templateGroup.templateGroupId, TemplateGroup.ckRecordType),
            (noteTemplate.noteTemplateId, NoteTemplate.ckRecordType),
            (notebookTemplateGroup.notebookTemplateGroupId, NotebookTemplateGroup.ckRecordType),
            (journalTemplateGroup.journalTemplateGroupId, JournalTemplateGroup.ckRecordType),
            (savedView.savedViewId, SavedView.ckRecordType),
            (attachment.attachmentId, Attachment.ckRecordType),
            (board.canvasBoardId, CanvasBoard.ckRecordType),
            (card.canvasCardId, CanvasCard.ckRecordType),
            (connector.canvasConnectorId, CanvasConnector.ckRecordType),
            (plugin.pluginId, Plugin.ckRecordType)
        ] {
            let id = try #require(syncId)
            SyncRecordFactory.applyDeletion(recordID: .record(syncId: id, zoneID: zoneID), recordType: type, in: context)
        }

        #expect(library.isActive == false)
        #expect(notebook.isActive == false)
        #expect(tag.isActive == false)
        #expect(document.isActive == false)
        #expect(block.isActive == false)
        #expect(task.isActive == false)
        #expect(documentTag.isActive == false)
        #expect(documentNotebook.isActive == false)
        #expect(property.isActive == false)
        #expect(documentProperty.isActive == false)
        #expect(templateGroup.isActive == false)
        #expect(noteTemplate.isActive == false)
        #expect(notebookTemplateGroup.isActive == false)
        #expect(journalTemplateGroup.isActive == false)
        #expect(savedView.isActive == false)
        #expect(attachment.isActive == false)
        #expect(board.isActive == false)
        #expect(card.isActive == false)
        #expect(connector.isActive == false)
        #expect(plugin.isActive == false)
    }

    @Test func applyDeletionIgnoresAnUnknownRecordType() throws {
        let context = try makeContext()
        SyncRecordFactory.applyDeletion(recordID: .record(syncId: UUID(), zoneID: .library(UUID())), recordType: "SomethingElse", in: context)
        // No crash — covered by the default: break branch.
    }

}
