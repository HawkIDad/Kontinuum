// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BackupDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

/// Local, file-based snapshot mechanism — one JSON file per snapshot on disk, entirely
/// outside SwiftData/CloudKit. `createSnapshot(cause:in:)` is the single entry point any
/// future caller (bulk import, merge, manual) should trigger before a risky operation.
enum BackupDAL {

    static func backupsDirectory(in fileManager: FileManager = .default) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("Backups", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Encodes and immediately re-decodes before returning, so the result is always a
    /// detached, frozen copy — never a live reference into `context` that later mutations
    /// (including soft-deletes) could leak into. Captures every active library's full
    /// contents, not just the `Library` row itself — a snapshot that can't restore notes
    /// wouldn't protect anything.
    @discardableResult
    static func createSnapshot(cause: BackupCause, in context: ModelContext, directory: URL = backupsDirectory()) -> BackupSnapshot {
        let libraries = LibraryDAL.fetchActive(in: context)

        var documents: [Document] = []
        var blocks: [Block] = []
        var tags: [Tag] = []
        var documentTags: [DocumentTag] = []
        var notebooks: [Notebook] = []
        var documentNotebooks: [DocumentNotebook] = []
        var taskItems: [TaskItem] = []
        var properties: [Property] = []
        var documentProperties: [DocumentProperty] = []
        var templateGroups: [TemplateGroup] = []
        var noteTemplates: [NoteTemplate] = []
        var notebookTemplateGroups: [NotebookTemplateGroup] = []
        var journalTemplateGroups: [JournalTemplateGroup] = []
        var savedViews: [SavedView] = []
        var attachments: [Attachment] = []
        var canvasBoards: [CanvasBoard] = []
        var canvasCards: [CanvasCard] = []
        var canvasConnectors: [CanvasConnector] = []
        var plugins: [Plugin] = []

        for library in libraries {
            guard let libraryId = library.libraryId else { continue }

            let libraryDocuments = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
            documents.append(contentsOf: libraryDocuments)
            for document in libraryDocuments {
                guard let documentId = document.documentId else { continue }
                blocks.append(contentsOf: BlockDAL.fetchActive(documentId: documentId, in: context))
                taskItems.append(contentsOf: TaskDAL.fetchActive(documentId: documentId, in: context))
                attachments.append(contentsOf: AttachmentDAL.fetchActive(documentId: documentId, in: context))
            }

            tags.append(contentsOf: TagDAL.fetchActive(libraryId: libraryId, in: context))
            documentTags.append(contentsOf: fetchActiveDocumentTags(libraryId: libraryId, in: context))
            notebooks.append(contentsOf: NotebookDAL.fetchActive(libraryId: libraryId, in: context))
            documentNotebooks.append(contentsOf: fetchActiveDocumentNotebooks(libraryId: libraryId, in: context))
            properties.append(contentsOf: PropertyDAL.fetchActive(libraryId: libraryId, in: context))
            documentProperties.append(contentsOf: fetchActiveDocumentProperties(libraryId: libraryId, in: context))

            let libraryGroups = TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context)
            templateGroups.append(contentsOf: libraryGroups)
            for group in libraryGroups {
                guard let templateGroupId = group.templateGroupId else { continue }
                noteTemplates.append(contentsOf: TemplateDAL.fetchActiveTemplates(templateGroupId: templateGroupId, in: context))
            }
            notebookTemplateGroups.append(contentsOf: fetchActiveNotebookTemplateGroups(libraryId: libraryId, in: context))
            journalTemplateGroups.append(contentsOf: fetchActiveJournalTemplateGroups(libraryId: libraryId, in: context))
            savedViews.append(contentsOf: SavedViewDAL.fetchActive(libraryId: libraryId, in: context))

            let libraryBoards = CanvasDAL.fetchActiveBoards(libraryId: libraryId, in: context)
            canvasBoards.append(contentsOf: libraryBoards)
            for board in libraryBoards {
                guard let boardId = board.canvasBoardId else { continue }
                canvasCards.append(contentsOf: CanvasDAL.fetchActiveCards(boardId: boardId, in: context))
                canvasConnectors.append(contentsOf: CanvasDAL.fetchActiveConnectors(boardId: boardId, in: context))
            }

            plugins.append(contentsOf: PluginDAL.fetchActive(libraryId: libraryId, in: context))
        }

        let snapshot = BackupSnapshot(
            snapshotId: UUID(), createdOn: Date(), cause: cause, libraries: libraries,
            documents: documents, blocks: blocks, tags: tags, documentTags: documentTags,
            notebooks: notebooks, documentNotebooks: documentNotebooks, taskItems: taskItems,
            properties: properties, documentProperties: documentProperties,
            templateGroups: templateGroups, noteTemplates: noteTemplates,
            notebookTemplateGroups: notebookTemplateGroups, journalTemplateGroups: journalTemplateGroups,
            savedViews: savedViews, attachments: attachments,
            canvasBoards: canvasBoards, canvasCards: canvasCards, canvasConnectors: canvasConnectors,
            plugins: plugins
        )

        guard let data = try? JSONEncoder().encode(snapshot) else { return snapshot }
        // Phase 11 (Security-Local Files): explicit `.completeFileProtection`, stronger than the
        // app container's default `NSFileProtectionCompleteUntilFirstUserAuthentication` — a
        // snapshot is a full copy of every active library's content, so it deserves the same
        // protection level as the live SwiftData store, not the weaker container default.
        try? data.write(to: directory.appendingPathComponent("\(snapshot.snapshotId.uuidString).json"), options: .completeFileProtection)

        return (try? JSONDecoder().decode(BackupSnapshot.self, from: data)) ?? snapshot
    }

    private static func fetchActiveDocumentTags(libraryId: UUID, in context: ModelContext) -> [DocumentTag] {
        let predicate = #Predicate<DocumentTag> { $0.libraryId == libraryId && $0.isActive == true }
        return (try? context.fetch(FetchDescriptor<DocumentTag>(predicate: predicate))) ?? []
    }

    private static func fetchActiveDocumentNotebooks(libraryId: UUID, in context: ModelContext) -> [DocumentNotebook] {
        let predicate = #Predicate<DocumentNotebook> { $0.libraryId == libraryId && $0.isActive == true }
        return (try? context.fetch(FetchDescriptor<DocumentNotebook>(predicate: predicate))) ?? []
    }

    private static func fetchActiveDocumentProperties(libraryId: UUID, in context: ModelContext) -> [DocumentProperty] {
        let predicate = #Predicate<DocumentProperty> { $0.libraryId == libraryId && $0.isActive == true }
        return (try? context.fetch(FetchDescriptor<DocumentProperty>(predicate: predicate))) ?? []
    }

    private static func fetchActiveNotebookTemplateGroups(libraryId: UUID, in context: ModelContext) -> [NotebookTemplateGroup] {
        let predicate = #Predicate<NotebookTemplateGroup> { $0.libraryId == libraryId && $0.isActive == true }
        return (try? context.fetch(FetchDescriptor<NotebookTemplateGroup>(predicate: predicate))) ?? []
    }

    private static func fetchActiveJournalTemplateGroups(libraryId: UUID, in context: ModelContext) -> [JournalTemplateGroup] {
        let predicate = #Predicate<JournalTemplateGroup> { $0.libraryId == libraryId && $0.isActive == true }
        return (try? context.fetch(FetchDescriptor<JournalTemplateGroup>(predicate: predicate))) ?? []
    }

    static func listSnapshots(in directory: URL = backupsDirectory()) -> [BackupSnapshot] {
        let decoder = JSONDecoder()
        let urls = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []

        let snapshots = urls.compactMap { url -> BackupSnapshot? in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(BackupSnapshot.self, from: data)
        }

        return snapshots.sorted { $0.createdOn > $1.createdOn }
    }

    /// Restores every captured record, upserting by its `{model}Id` — an existing row is
    /// updated in place, a missing one is reinserted with the snapshot's original id.
    static func restore(_ snapshot: BackupSnapshot, in context: ModelContext) {
        for snapshotLibrary in snapshot.libraries {
            guard let targetId = snapshotLibrary.libraryId else { continue }
            let predicate = #Predicate<Library> { $0.libraryId == targetId }
            let descriptor = FetchDescriptor<Library>(predicate: predicate)

            if let existing = try? context.fetch(descriptor).first {
                existing.name = snapshotLibrary.name
                existing.isActive = snapshotLibrary.isActive
                existing.updatedOn = Date()
            } else {
                let restored = Library(name: snapshotLibrary.name ?? "Restored Library")
                restored.libraryId = snapshotLibrary.libraryId
                restored.createdOn = snapshotLibrary.createdOn
                restored.createdBy = snapshotLibrary.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotLibrary.updatedBy
                restored.isActive = snapshotLibrary.isActive
                context.insert(restored)
            }
        }

        for snapshotDocument in snapshot.documents {
            guard let targetId = snapshotDocument.documentId else { continue }
            let predicate = #Predicate<Document> { $0.documentId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<Document>(predicate: predicate)).first {
                existing.title = snapshotDocument.title
                existing.content = snapshotDocument.content
                existing.libraryId = snapshotDocument.libraryId
                existing.isJournalEntry = snapshotDocument.isJournalEntry
                existing.journalDate = snapshotDocument.journalDate
                existing.isActive = snapshotDocument.isActive
                existing.updatedOn = Date()
            } else {
                let restored = Document(title: snapshotDocument.title ?? "", content: snapshotDocument.content ?? "", libraryId: snapshotDocument.libraryId ?? UUID())
                restored.documentId = snapshotDocument.documentId
                restored.isJournalEntry = snapshotDocument.isJournalEntry
                restored.journalDate = snapshotDocument.journalDate
                restored.createdOn = snapshotDocument.createdOn
                restored.createdBy = snapshotDocument.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotDocument.updatedBy
                restored.isActive = snapshotDocument.isActive
                context.insert(restored)
            }
        }

        for snapshotBlock in snapshot.blocks {
            guard let targetId = snapshotBlock.blockId else { continue }
            let predicate = #Predicate<Block> { $0.blockId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<Block>(predicate: predicate)).first {
                existing.content = snapshotBlock.content
                existing.anchor = snapshotBlock.anchor
                existing.sortOrder = snapshotBlock.sortOrder
                existing.documentId = snapshotBlock.documentId
                existing.isActive = snapshotBlock.isActive
                existing.updatedOn = Date()
            } else {
                let restored = Block(content: snapshotBlock.content ?? "", anchor: snapshotBlock.anchor ?? "", sortOrder: snapshotBlock.sortOrder ?? 0, documentId: snapshotBlock.documentId ?? UUID())
                restored.blockId = snapshotBlock.blockId
                restored.createdOn = snapshotBlock.createdOn
                restored.createdBy = snapshotBlock.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotBlock.updatedBy
                restored.isActive = snapshotBlock.isActive
                context.insert(restored)
            }
        }

        for snapshotTag in snapshot.tags {
            guard let targetId = snapshotTag.tagId else { continue }
            let predicate = #Predicate<Tag> { $0.tagId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<Tag>(predicate: predicate)).first {
                existing.name = snapshotTag.name
                existing.libraryId = snapshotTag.libraryId
                existing.isActive = snapshotTag.isActive
                existing.updatedOn = Date()
            } else {
                let restored = Tag(name: snapshotTag.name ?? "", libraryId: snapshotTag.libraryId ?? UUID())
                restored.tagId = snapshotTag.tagId
                restored.createdOn = snapshotTag.createdOn
                restored.createdBy = snapshotTag.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotTag.updatedBy
                restored.isActive = snapshotTag.isActive
                context.insert(restored)
            }
        }

        for snapshotDocumentTag in snapshot.documentTags {
            guard let targetId = snapshotDocumentTag.documentTagId else { continue }
            let predicate = #Predicate<DocumentTag> { $0.documentTagId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<DocumentTag>(predicate: predicate)).first {
                existing.documentId = snapshotDocumentTag.documentId
                existing.tagId = snapshotDocumentTag.tagId
                existing.libraryId = snapshotDocumentTag.libraryId
                existing.isActive = snapshotDocumentTag.isActive
                existing.updatedOn = Date()
            } else {
                let restored = DocumentTag(documentId: snapshotDocumentTag.documentId ?? UUID(), tagId: snapshotDocumentTag.tagId ?? UUID(), libraryId: snapshotDocumentTag.libraryId ?? UUID())
                restored.documentTagId = snapshotDocumentTag.documentTagId
                restored.createdOn = snapshotDocumentTag.createdOn
                restored.createdBy = snapshotDocumentTag.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotDocumentTag.updatedBy
                restored.isActive = snapshotDocumentTag.isActive
                context.insert(restored)
            }
        }

        for snapshotNotebook in snapshot.notebooks {
            guard let targetId = snapshotNotebook.notebookId else { continue }
            let predicate = #Predicate<Notebook> { $0.notebookId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<Notebook>(predicate: predicate)).first {
                existing.name = snapshotNotebook.name
                existing.libraryId = snapshotNotebook.libraryId
                existing.isActive = snapshotNotebook.isActive
                existing.updatedOn = Date()
            } else {
                let restored = Notebook(name: snapshotNotebook.name ?? "", libraryId: snapshotNotebook.libraryId ?? UUID())
                restored.notebookId = snapshotNotebook.notebookId
                restored.createdOn = snapshotNotebook.createdOn
                restored.createdBy = snapshotNotebook.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotNotebook.updatedBy
                restored.isActive = snapshotNotebook.isActive
                context.insert(restored)
            }
        }

        for snapshotDocumentNotebook in snapshot.documentNotebooks {
            guard let targetId = snapshotDocumentNotebook.documentNotebookId else { continue }
            let predicate = #Predicate<DocumentNotebook> { $0.documentNotebookId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<DocumentNotebook>(predicate: predicate)).first {
                existing.documentId = snapshotDocumentNotebook.documentId
                existing.notebookId = snapshotDocumentNotebook.notebookId
                existing.libraryId = snapshotDocumentNotebook.libraryId
                existing.isActive = snapshotDocumentNotebook.isActive
                existing.updatedOn = Date()
            } else {
                let restored = DocumentNotebook(documentId: snapshotDocumentNotebook.documentId ?? UUID(), notebookId: snapshotDocumentNotebook.notebookId ?? UUID(), libraryId: snapshotDocumentNotebook.libraryId ?? UUID())
                restored.documentNotebookId = snapshotDocumentNotebook.documentNotebookId
                restored.createdOn = snapshotDocumentNotebook.createdOn
                restored.createdBy = snapshotDocumentNotebook.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotDocumentNotebook.updatedBy
                restored.isActive = snapshotDocumentNotebook.isActive
                context.insert(restored)
            }
        }

        for snapshotTask in snapshot.taskItems {
            guard let targetId = snapshotTask.taskItemId else { continue }
            let predicate = #Predicate<TaskItem> { $0.taskItemId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<TaskItem>(predicate: predicate)).first {
                existing.content = snapshotTask.content
                existing.isDone = snapshotTask.isDone
                existing.documentId = snapshotTask.documentId
                existing.blockId = snapshotTask.blockId
                existing.libraryId = snapshotTask.libraryId
                existing.dueDate = snapshotTask.dueDate
                existing.priority = snapshotTask.priority
                existing.recurrenceRule = snapshotTask.recurrenceRule
                existing.isActive = snapshotTask.isActive
                existing.updatedOn = Date()
            } else {
                let restored = TaskItem(content: snapshotTask.content ?? "", isDone: snapshotTask.isDone ?? false, documentId: snapshotTask.documentId ?? UUID(), blockId: snapshotTask.blockId ?? UUID(), libraryId: snapshotTask.libraryId ?? UUID())
                restored.taskItemId = snapshotTask.taskItemId
                restored.dueDate = snapshotTask.dueDate
                restored.priority = snapshotTask.priority
                restored.recurrenceRule = snapshotTask.recurrenceRule
                restored.createdOn = snapshotTask.createdOn
                restored.createdBy = snapshotTask.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotTask.updatedBy
                restored.isActive = snapshotTask.isActive
                context.insert(restored)
            }
        }

        for snapshotProperty in snapshot.properties {
            guard let targetId = snapshotProperty.propertyId else { continue }
            let predicate = #Predicate<Property> { $0.propertyId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<Property>(predicate: predicate)).first {
                existing.name = snapshotProperty.name
                existing.valueType = snapshotProperty.valueType
                existing.libraryId = snapshotProperty.libraryId
                existing.isActive = snapshotProperty.isActive
                existing.updatedOn = Date()
            } else {
                let valueType = snapshotProperty.valueType.flatMap(PropertyValueType.init) ?? .text
                let restored = Property(name: snapshotProperty.name ?? "", valueType: valueType, libraryId: snapshotProperty.libraryId ?? UUID())
                restored.propertyId = snapshotProperty.propertyId
                restored.createdOn = snapshotProperty.createdOn
                restored.createdBy = snapshotProperty.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotProperty.updatedBy
                restored.isActive = snapshotProperty.isActive
                context.insert(restored)
            }
        }

        for snapshotDocumentProperty in snapshot.documentProperties {
            guard let targetId = snapshotDocumentProperty.documentPropertyId else { continue }
            let predicate = #Predicate<DocumentProperty> { $0.documentPropertyId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<DocumentProperty>(predicate: predicate)).first {
                existing.documentId = snapshotDocumentProperty.documentId
                existing.propertyId = snapshotDocumentProperty.propertyId
                existing.libraryId = snapshotDocumentProperty.libraryId
                existing.value = snapshotDocumentProperty.value
                existing.valueType = snapshotDocumentProperty.valueType
                existing.isActive = snapshotDocumentProperty.isActive
                existing.updatedOn = Date()
            } else {
                let valueType = snapshotDocumentProperty.valueType.flatMap(PropertyValueType.init) ?? .text
                let restored = DocumentProperty(documentId: snapshotDocumentProperty.documentId ?? UUID(), propertyId: snapshotDocumentProperty.propertyId ?? UUID(), libraryId: snapshotDocumentProperty.libraryId ?? UUID(), value: snapshotDocumentProperty.value ?? "", valueType: valueType)
                restored.documentPropertyId = snapshotDocumentProperty.documentPropertyId
                restored.createdOn = snapshotDocumentProperty.createdOn
                restored.createdBy = snapshotDocumentProperty.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotDocumentProperty.updatedBy
                restored.isActive = snapshotDocumentProperty.isActive
                context.insert(restored)
            }
        }

        for snapshotGroup in snapshot.templateGroups {
            guard let targetId = snapshotGroup.templateGroupId else { continue }
            let predicate = #Predicate<TemplateGroup> { $0.templateGroupId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<TemplateGroup>(predicate: predicate)).first {
                existing.name = snapshotGroup.name
                existing.libraryId = snapshotGroup.libraryId
                existing.sourcePackId = snapshotGroup.sourcePackId
                existing.sourcePackVersion = snapshotGroup.sourcePackVersion
                existing.isActive = snapshotGroup.isActive
                existing.updatedOn = Date()
            } else {
                let restored = TemplateGroup(name: snapshotGroup.name ?? "", libraryId: snapshotGroup.libraryId ?? UUID())
                restored.templateGroupId = snapshotGroup.templateGroupId
                restored.sourcePackId = snapshotGroup.sourcePackId
                restored.sourcePackVersion = snapshotGroup.sourcePackVersion
                restored.createdOn = snapshotGroup.createdOn
                restored.createdBy = snapshotGroup.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotGroup.updatedBy
                restored.isActive = snapshotGroup.isActive
                context.insert(restored)
            }
        }

        for snapshotTemplate in snapshot.noteTemplates {
            guard let targetId = snapshotTemplate.noteTemplateId else { continue }
            let predicate = #Predicate<NoteTemplate> { $0.noteTemplateId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<NoteTemplate>(predicate: predicate)).first {
                existing.name = snapshotTemplate.name
                existing.templateGroupId = snapshotTemplate.templateGroupId
                existing.libraryId = snapshotTemplate.libraryId
                existing.fieldsJSON = snapshotTemplate.fieldsJSON
                existing.bodyTemplate = snapshotTemplate.bodyTemplate
                existing.isActive = snapshotTemplate.isActive
                existing.updatedOn = Date()
            } else {
                let restored = NoteTemplate(name: snapshotTemplate.name ?? "", templateGroupId: snapshotTemplate.templateGroupId ?? UUID(), libraryId: snapshotTemplate.libraryId ?? UUID())
                restored.noteTemplateId = snapshotTemplate.noteTemplateId
                restored.fieldsJSON = snapshotTemplate.fieldsJSON
                restored.bodyTemplate = snapshotTemplate.bodyTemplate
                restored.createdOn = snapshotTemplate.createdOn
                restored.createdBy = snapshotTemplate.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotTemplate.updatedBy
                restored.isActive = snapshotTemplate.isActive
                context.insert(restored)
            }
        }

        for snapshotNotebookTemplateGroup in snapshot.notebookTemplateGroups {
            guard let targetId = snapshotNotebookTemplateGroup.notebookTemplateGroupId else { continue }
            let predicate = #Predicate<NotebookTemplateGroup> { $0.notebookTemplateGroupId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<NotebookTemplateGroup>(predicate: predicate)).first {
                existing.notebookId = snapshotNotebookTemplateGroup.notebookId
                existing.templateGroupId = snapshotNotebookTemplateGroup.templateGroupId
                existing.libraryId = snapshotNotebookTemplateGroup.libraryId
                existing.isActive = snapshotNotebookTemplateGroup.isActive
                existing.updatedOn = Date()
            } else {
                let restored = NotebookTemplateGroup(notebookId: snapshotNotebookTemplateGroup.notebookId ?? UUID(), templateGroupId: snapshotNotebookTemplateGroup.templateGroupId ?? UUID(), libraryId: snapshotNotebookTemplateGroup.libraryId ?? UUID())
                restored.notebookTemplateGroupId = snapshotNotebookTemplateGroup.notebookTemplateGroupId
                restored.createdOn = snapshotNotebookTemplateGroup.createdOn
                restored.createdBy = snapshotNotebookTemplateGroup.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotNotebookTemplateGroup.updatedBy
                restored.isActive = snapshotNotebookTemplateGroup.isActive
                context.insert(restored)
            }
        }

        for snapshotJournalTemplateGroup in snapshot.journalTemplateGroups {
            guard let targetId = snapshotJournalTemplateGroup.journalTemplateGroupId else { continue }
            let predicate = #Predicate<JournalTemplateGroup> { $0.journalTemplateGroupId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<JournalTemplateGroup>(predicate: predicate)).first {
                existing.libraryId = snapshotJournalTemplateGroup.libraryId
                existing.templateGroupId = snapshotJournalTemplateGroup.templateGroupId
                existing.isActive = snapshotJournalTemplateGroup.isActive
                existing.updatedOn = Date()
            } else {
                let restored = JournalTemplateGroup(libraryId: snapshotJournalTemplateGroup.libraryId ?? UUID(), templateGroupId: snapshotJournalTemplateGroup.templateGroupId ?? UUID())
                restored.journalTemplateGroupId = snapshotJournalTemplateGroup.journalTemplateGroupId
                restored.createdOn = snapshotJournalTemplateGroup.createdOn
                restored.createdBy = snapshotJournalTemplateGroup.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotJournalTemplateGroup.updatedBy
                restored.isActive = snapshotJournalTemplateGroup.isActive
                context.insert(restored)
            }
        }

        for snapshotSavedView in snapshot.savedViews {
            guard let targetId = snapshotSavedView.savedViewId else { continue }
            let predicate = #Predicate<SavedView> { $0.savedViewId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<SavedView>(predicate: predicate)).first {
                existing.name = snapshotSavedView.name
                existing.libraryId = snapshotSavedView.libraryId
                existing.queryType = snapshotSavedView.queryType
                existing.definitionJSON = snapshotSavedView.definitionJSON
                existing.sortOrder = snapshotSavedView.sortOrder
                existing.isActive = snapshotSavedView.isActive
                existing.updatedOn = Date()
            } else {
                let queryType = snapshotSavedView.queryType.flatMap(SavedViewQueryType.init) ?? .search
                let restored = SavedView(name: snapshotSavedView.name ?? "", libraryId: snapshotSavedView.libraryId ?? UUID(), queryType: queryType, sortOrder: snapshotSavedView.sortOrder ?? 0)
                restored.savedViewId = snapshotSavedView.savedViewId
                restored.definitionJSON = snapshotSavedView.definitionJSON
                restored.createdOn = snapshotSavedView.createdOn
                restored.createdBy = snapshotSavedView.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotSavedView.updatedBy
                restored.isActive = snapshotSavedView.isActive
                context.insert(restored)
            }
        }

        for snapshotAttachment in snapshot.attachments {
            guard let targetId = snapshotAttachment.attachmentId else { continue }
            let predicate = #Predicate<Attachment> { $0.attachmentId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<Attachment>(predicate: predicate)).first {
                existing.documentId = snapshotAttachment.documentId
                existing.fileName = snapshotAttachment.fileName
                existing.relativePath = snapshotAttachment.relativePath
                existing.mimeType = snapshotAttachment.mimeType
                existing.isActive = snapshotAttachment.isActive
                existing.updatedOn = Date()
            } else {
                let restored = Attachment(documentId: snapshotAttachment.documentId ?? UUID(), fileName: snapshotAttachment.fileName ?? "", relativePath: snapshotAttachment.relativePath ?? "", mimeType: snapshotAttachment.mimeType ?? "")
                restored.attachmentId = snapshotAttachment.attachmentId
                restored.createdOn = snapshotAttachment.createdOn
                restored.createdBy = snapshotAttachment.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotAttachment.updatedBy
                restored.isActive = snapshotAttachment.isActive
                context.insert(restored)
            }
        }

        for snapshotBoard in snapshot.canvasBoards {
            guard let targetId = snapshotBoard.canvasBoardId else { continue }
            let predicate = #Predicate<CanvasBoard> { $0.canvasBoardId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<CanvasBoard>(predicate: predicate)).first {
                existing.name = snapshotBoard.name
                existing.libraryId = snapshotBoard.libraryId
                existing.boundDocumentId = snapshotBoard.boundDocumentId
                existing.isActive = snapshotBoard.isActive
                existing.updatedOn = Date()
            } else {
                let restored = CanvasBoard(name: snapshotBoard.name ?? "", libraryId: snapshotBoard.libraryId ?? UUID())
                restored.canvasBoardId = snapshotBoard.canvasBoardId
                restored.boundDocumentId = snapshotBoard.boundDocumentId
                restored.createdOn = snapshotBoard.createdOn
                restored.createdBy = snapshotBoard.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotBoard.updatedBy
                restored.isActive = snapshotBoard.isActive
                context.insert(restored)
            }
        }

        for snapshotCard in snapshot.canvasCards {
            guard let targetId = snapshotCard.canvasCardId else { continue }
            let predicate = #Predicate<CanvasCard> { $0.canvasCardId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<CanvasCard>(predicate: predicate)).first {
                existing.canvasBoardId = snapshotCard.canvasBoardId
                existing.cardType = snapshotCard.cardType
                existing.documentId = snapshotCard.documentId
                existing.attachmentId = snapshotCard.attachmentId
                existing.url = snapshotCard.url
                existing.label = snapshotCard.label
                existing.positionX = snapshotCard.positionX
                existing.positionY = snapshotCard.positionY
                existing.width = snapshotCard.width
                existing.height = snapshotCard.height
                existing.color = snapshotCard.color
                existing.isActive = snapshotCard.isActive
                existing.updatedOn = Date()
            } else {
                let cardType = snapshotCard.cardType.flatMap(CanvasCardType.init) ?? .note
                let restored = CanvasCard(canvasBoardId: snapshotCard.canvasBoardId ?? UUID(), cardType: cardType, positionX: snapshotCard.positionX ?? 0, positionY: snapshotCard.positionY ?? 0, width: snapshotCard.width ?? CanvasDAL.defaultCardWidth, height: snapshotCard.height ?? CanvasDAL.defaultCardHeight)
                restored.canvasCardId = snapshotCard.canvasCardId
                restored.documentId = snapshotCard.documentId
                restored.attachmentId = snapshotCard.attachmentId
                restored.url = snapshotCard.url
                restored.label = snapshotCard.label
                restored.color = snapshotCard.color
                restored.createdOn = snapshotCard.createdOn
                restored.createdBy = snapshotCard.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotCard.updatedBy
                restored.isActive = snapshotCard.isActive
                context.insert(restored)
            }
        }

        for snapshotConnector in snapshot.canvasConnectors {
            guard let targetId = snapshotConnector.canvasConnectorId else { continue }
            let predicate = #Predicate<CanvasConnector> { $0.canvasConnectorId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<CanvasConnector>(predicate: predicate)).first {
                existing.canvasBoardId = snapshotConnector.canvasBoardId
                existing.fromCardId = snapshotConnector.fromCardId
                existing.toCardId = snapshotConnector.toCardId
                existing.fromSide = snapshotConnector.fromSide
                existing.toSide = snapshotConnector.toSide
                existing.color = snapshotConnector.color
                existing.label = snapshotConnector.label
                existing.isActive = snapshotConnector.isActive
                existing.updatedOn = Date()
            } else {
                let restored = CanvasConnector(canvasBoardId: snapshotConnector.canvasBoardId ?? UUID(), fromCardId: snapshotConnector.fromCardId ?? UUID(), toCardId: snapshotConnector.toCardId ?? UUID())
                restored.canvasConnectorId = snapshotConnector.canvasConnectorId
                restored.fromSide = snapshotConnector.fromSide
                restored.toSide = snapshotConnector.toSide
                restored.color = snapshotConnector.color
                restored.label = snapshotConnector.label
                restored.createdOn = snapshotConnector.createdOn
                restored.createdBy = snapshotConnector.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotConnector.updatedBy
                restored.isActive = snapshotConnector.isActive
                context.insert(restored)
            }
        }

        for snapshotPlugin in snapshot.plugins {
            guard let targetId = snapshotPlugin.pluginId else { continue }
            let predicate = #Predicate<Plugin> { $0.pluginId == targetId }

            if let existing = try? context.fetch(FetchDescriptor<Plugin>(predicate: predicate)).first {
                existing.name = snapshotPlugin.name
                existing.libraryId = snapshotPlugin.libraryId
                existing.entryScript = snapshotPlugin.entryScript
                existing.permissionsJSON = snapshotPlugin.permissionsJSON
                existing.isEnabled = snapshotPlugin.isEnabled
                existing.isActive = snapshotPlugin.isActive
                existing.updatedOn = Date()
            } else {
                let restored = Plugin(name: snapshotPlugin.name ?? "", libraryId: snapshotPlugin.libraryId ?? UUID(), entryScript: snapshotPlugin.entryScript ?? "", permissions: [])
                restored.pluginId = snapshotPlugin.pluginId
                restored.permissionsJSON = snapshotPlugin.permissionsJSON
                restored.isEnabled = snapshotPlugin.isEnabled
                restored.createdOn = snapshotPlugin.createdOn
                restored.createdBy = snapshotPlugin.createdBy
                restored.updatedOn = Date()
                restored.updatedBy = snapshotPlugin.updatedBy
                restored.isActive = snapshotPlugin.isActive
                context.insert(restored)
            }
        }
    }

}
