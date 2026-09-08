// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BackupSnapshot.swift
//  NoteBytez
//

import Foundation

enum BackupCause: String, Codable {
    case automatic
    case manual
}

/// A point-in-time capture of every active library's data — not just the `Library` rows
/// themselves, but their `Document`/`Block`/`Tag`/`DocumentTag`/`Notebook`/`DocumentNotebook`/
/// `TaskItem`/`Property`/`DocumentProperty`/`TemplateGroup`/`NoteTemplate`/
/// `NotebookTemplateGroup`/`JournalTemplateGroup`/`SavedView`/`Attachment`/`CanvasBoard`/
/// `CanvasCard`/`CanvasConnector`/`Plugin` contents, since the whole point of a snapshot is to be able to
/// roll back a risky operation (e.g. a bad import) without losing notes. `Attachment` metadata
/// only — file bytes are the iCloud ubiquity container's own backup responsibility, not this
/// app's (see `AttachmentStorage`). Deliberately a plain Codable struct, not a SwiftData `@Model`
/// — snapshots are a local, per-device safety net and must never sync via CloudKit. See
/// ARCHITECTURE.md.
struct BackupSnapshot: Codable, Identifiable {

    var snapshotId: UUID
    var createdOn: Date
    var cause: BackupCause
    var libraries: [Library]
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

    var id: UUID { snapshotId }

    init(snapshotId: UUID, createdOn: Date, cause: BackupCause, libraries: [Library], documents: [Document] = [], blocks: [Block] = [], tags: [Tag] = [], documentTags: [DocumentTag] = [], notebooks: [Notebook] = [], documentNotebooks: [DocumentNotebook] = [], taskItems: [TaskItem] = [], properties: [Property] = [], documentProperties: [DocumentProperty] = [], templateGroups: [TemplateGroup] = [], noteTemplates: [NoteTemplate] = [], notebookTemplateGroups: [NotebookTemplateGroup] = [], journalTemplateGroups: [JournalTemplateGroup] = [], savedViews: [SavedView] = [], attachments: [Attachment] = [], canvasBoards: [CanvasBoard] = [], canvasCards: [CanvasCard] = [], canvasConnectors: [CanvasConnector] = [], plugins: [Plugin] = []) {
        self.snapshotId = snapshotId
        self.createdOn = createdOn
        self.cause = cause
        self.libraries = libraries
        self.documents = documents
        self.blocks = blocks
        self.tags = tags
        self.documentTags = documentTags
        self.notebooks = notebooks
        self.documentNotebooks = documentNotebooks
        self.taskItems = taskItems
        self.properties = properties
        self.documentProperties = documentProperties
        self.templateGroups = templateGroups
        self.noteTemplates = noteTemplates
        self.notebookTemplateGroups = notebookTemplateGroups
        self.journalTemplateGroups = journalTemplateGroups
        self.savedViews = savedViews
        self.attachments = attachments
        self.canvasBoards = canvasBoards
        self.canvasCards = canvasCards
        self.canvasConnectors = canvasConnectors
        self.plugins = plugins
    }

    enum CodingKeys: String, CodingKey {
        case snapshotId, createdOn, cause, libraries, documents, blocks, tags, documentTags, notebooks, documentNotebooks, taskItems, properties, documentProperties, templateGroups, noteTemplates, notebookTemplateGroups, journalTemplateGroups, savedViews, attachments, canvasBoards, canvasCards, canvasConnectors, plugins
    }

    /// Manual `Decodable` (rather than relying on synthesis) so a snapshot file written before
    /// any of these keys existed still decodes — an absent key simply defaults to empty,
    /// instead of a hard decode failure.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.snapshotId = try container.decode(UUID.self, forKey: .snapshotId)
        self.createdOn = try container.decode(Date.self, forKey: .createdOn)
        self.cause = try container.decode(BackupCause.self, forKey: .cause)
        self.libraries = try container.decodeIfPresent([Library].self, forKey: .libraries) ?? []
        self.documents = try container.decodeIfPresent([Document].self, forKey: .documents) ?? []
        self.blocks = try container.decodeIfPresent([Block].self, forKey: .blocks) ?? []
        self.tags = try container.decodeIfPresent([Tag].self, forKey: .tags) ?? []
        self.documentTags = try container.decodeIfPresent([DocumentTag].self, forKey: .documentTags) ?? []
        self.notebooks = try container.decodeIfPresent([Notebook].self, forKey: .notebooks) ?? []
        self.documentNotebooks = try container.decodeIfPresent([DocumentNotebook].self, forKey: .documentNotebooks) ?? []
        self.taskItems = try container.decodeIfPresent([TaskItem].self, forKey: .taskItems) ?? []
        self.properties = try container.decodeIfPresent([Property].self, forKey: .properties) ?? []
        self.documentProperties = try container.decodeIfPresent([DocumentProperty].self, forKey: .documentProperties) ?? []
        self.templateGroups = try container.decodeIfPresent([TemplateGroup].self, forKey: .templateGroups) ?? []
        self.noteTemplates = try container.decodeIfPresent([NoteTemplate].self, forKey: .noteTemplates) ?? []
        self.notebookTemplateGroups = try container.decodeIfPresent([NotebookTemplateGroup].self, forKey: .notebookTemplateGroups) ?? []
        self.journalTemplateGroups = try container.decodeIfPresent([JournalTemplateGroup].self, forKey: .journalTemplateGroups) ?? []
        self.savedViews = try container.decodeIfPresent([SavedView].self, forKey: .savedViews) ?? []
        self.attachments = try container.decodeIfPresent([Attachment].self, forKey: .attachments) ?? []
        self.canvasBoards = try container.decodeIfPresent([CanvasBoard].self, forKey: .canvasBoards) ?? []
        self.canvasCards = try container.decodeIfPresent([CanvasCard].self, forKey: .canvasCards) ?? []
        self.canvasConnectors = try container.decodeIfPresent([CanvasConnector].self, forKey: .canvasConnectors) ?? []
        self.plugins = try container.decodeIfPresent([Plugin].self, forKey: .plugins) ?? []
    }

}
