// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

enum TemplateDAL {

    /// Where a Template Picker is being shown from — drives which `TemplateGroup`s (and so
    /// which `NoteTemplate`s) are offered, per NoteBytez-ReleaseFeatures.md's picker-scoping
    /// rule: inside a Notebook, only that Notebook's attached group(s); in the Journal, only
    /// the library's attached journal group(s); neither, every template in the library.
    enum PickerScope {
        case notebook(UUID)
        case journal
        case library
    }

    // MARK: - TemplateGroup CRUD

    @discardableResult
    static func createGroup(name: String, libraryId: UUID, in context: ModelContext) -> TemplateGroup {
        let group = TemplateGroup(name: name, libraryId: libraryId)
        context.insert(group)
        SyncEngine.shared.recordChanged(group, in: context)
        return group
    }

    static func fetchActiveGroups(libraryId: UUID, in context: ModelContext) -> [TemplateGroup] {
        let predicate = #Predicate<TemplateGroup> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<TemplateGroup>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func renameGroup(_ group: TemplateGroup, to name: String, in context: ModelContext) {
        group.name = name
        group.updatedOn = Date()
        SyncEngine.shared.recordChanged(group, in: context)
    }

    /// Soft-deletes the group along with every `NoteTemplate` in it and every Notebook/Journal
    /// attachment referencing it — a deleted group shouldn't leave orphaned templates or
    /// dangling joins a picker could still surface.
    static func deleteGroup(_ group: TemplateGroup, in context: ModelContext) {
        guard let templateGroupId = group.templateGroupId else { return }

        for template in fetchActiveTemplates(templateGroupId: templateGroupId, in: context) {
            deleteTemplate(template, in: context)
        }

        let notebookPredicate = #Predicate<NotebookTemplateGroup> { $0.templateGroupId == templateGroupId && $0.isActive == true }
        for join in (try? context.fetch(FetchDescriptor<NotebookTemplateGroup>(predicate: notebookPredicate))) ?? [] {
            join.isActive = false
            join.updatedOn = Date()
            SyncEngine.shared.recordChanged(join, in: context)
        }

        let journalPredicate = #Predicate<JournalTemplateGroup> { $0.templateGroupId == templateGroupId && $0.isActive == true }
        for join in (try? context.fetch(FetchDescriptor<JournalTemplateGroup>(predicate: journalPredicate))) ?? [] {
            join.isActive = false
            join.updatedOn = Date()
            SyncEngine.shared.recordChanged(join, in: context)
        }

        group.isActive = false
        group.updatedOn = Date()
        SyncEngine.shared.recordChanged(group, in: context)
    }

    // MARK: - NoteTemplate CRUD

    @discardableResult
    static func createTemplate(name: String, templateGroupId: UUID, libraryId: UUID, fields: [NoteTemplateField] = [], bodyTemplate: String? = nil, in context: ModelContext) -> NoteTemplate {
        let template = NoteTemplate(name: name, templateGroupId: templateGroupId, libraryId: libraryId, fields: fields, bodyTemplate: bodyTemplate)
        context.insert(template)
        SyncEngine.shared.recordChanged(template, in: context)
        return template
    }

    static func fetchActiveTemplates(templateGroupId: UUID, in context: ModelContext) -> [NoteTemplate] {
        let predicate = #Predicate<NoteTemplate> { $0.templateGroupId == templateGroupId && $0.isActive == true }
        let descriptor = FetchDescriptor<NoteTemplate>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Every active template in the library, regardless of group — the fallback picker scope
    /// (`PickerScope.library`) and the Template Manager's own use.
    static func fetchActiveTemplates(libraryId: UUID, in context: ModelContext) -> [NoteTemplate] {
        let predicate = #Predicate<NoteTemplate> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<NoteTemplate>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func rename(_ template: NoteTemplate, to name: String, in context: ModelContext) {
        template.name = name
        template.updatedOn = Date()
        SyncEngine.shared.recordChanged(template, in: context)
    }

    static func updateFields(_ template: NoteTemplate, fields: [NoteTemplateField], in context: ModelContext) {
        template.fields = fields
        template.updatedOn = Date()
        SyncEngine.shared.recordChanged(template, in: context)
    }

    static func updateBody(_ template: NoteTemplate, bodyTemplate: String?, in context: ModelContext) {
        template.bodyTemplate = bodyTemplate
        template.updatedOn = Date()
        SyncEngine.shared.recordChanged(template, in: context)
    }

    static func deleteTemplate(_ template: NoteTemplate, in context: ModelContext) {
        template.isActive = false
        template.updatedOn = Date()
        SyncEngine.shared.recordChanged(template, in: context)
    }

    // MARK: - Notebook/Journal attachment

    @discardableResult
    static func attachToNotebook(templateGroupId: UUID, notebookId: UUID, libraryId: UUID, in context: ModelContext) -> NotebookTemplateGroup {
        let predicate = #Predicate<NotebookTemplateGroup> { $0.notebookId == notebookId && $0.templateGroupId == templateGroupId }
        if let existing = (try? context.fetch(FetchDescriptor<NotebookTemplateGroup>(predicate: predicate)))?.first {
            if existing.isActive != true {
                existing.isActive = true
                existing.updatedOn = Date()
                SyncEngine.shared.recordChanged(existing, in: context)
            }
            return existing
        }
        let join = NotebookTemplateGroup(notebookId: notebookId, templateGroupId: templateGroupId, libraryId: libraryId)
        context.insert(join)
        SyncEngine.shared.recordChanged(join, in: context)
        return join
    }

    static func detachFromNotebook(templateGroupId: UUID, notebookId: UUID, in context: ModelContext) {
        let predicate = #Predicate<NotebookTemplateGroup> { $0.notebookId == notebookId && $0.templateGroupId == templateGroupId && $0.isActive == true }
        guard let join = (try? context.fetch(FetchDescriptor<NotebookTemplateGroup>(predicate: predicate)))?.first else { return }
        join.isActive = false
        join.updatedOn = Date()
        SyncEngine.shared.recordChanged(join, in: context)
    }

    static func templateGroups(forNotebook notebookId: UUID, libraryId: UUID, in context: ModelContext) -> [TemplateGroup] {
        let predicate = #Predicate<NotebookTemplateGroup> { $0.notebookId == notebookId && $0.isActive == true }
        let joins = (try? context.fetch(FetchDescriptor<NotebookTemplateGroup>(predicate: predicate))) ?? []
        let groupIds = Set(joins.compactMap { $0.templateGroupId })
        return fetchActiveGroups(libraryId: libraryId, in: context).filter { group in
            guard let groupId = group.templateGroupId else { return false }
            return groupIds.contains(groupId)
        }
    }

    @discardableResult
    static func attachToJournal(templateGroupId: UUID, libraryId: UUID, in context: ModelContext) -> JournalTemplateGroup {
        let predicate = #Predicate<JournalTemplateGroup> { $0.libraryId == libraryId && $0.templateGroupId == templateGroupId }
        if let existing = (try? context.fetch(FetchDescriptor<JournalTemplateGroup>(predicate: predicate)))?.first {
            if existing.isActive != true {
                existing.isActive = true
                existing.updatedOn = Date()
                SyncEngine.shared.recordChanged(existing, in: context)
            }
            return existing
        }
        let join = JournalTemplateGroup(libraryId: libraryId, templateGroupId: templateGroupId)
        context.insert(join)
        SyncEngine.shared.recordChanged(join, in: context)
        return join
    }

    static func detachFromJournal(templateGroupId: UUID, libraryId: UUID, in context: ModelContext) {
        let predicate = #Predicate<JournalTemplateGroup> { $0.libraryId == libraryId && $0.templateGroupId == templateGroupId && $0.isActive == true }
        guard let join = (try? context.fetch(FetchDescriptor<JournalTemplateGroup>(predicate: predicate)))?.first else { return }
        join.isActive = false
        join.updatedOn = Date()
        SyncEngine.shared.recordChanged(join, in: context)
    }

    static func templateGroups(forJournalLibraryId libraryId: UUID, in context: ModelContext) -> [TemplateGroup] {
        let predicate = #Predicate<JournalTemplateGroup> { $0.libraryId == libraryId && $0.isActive == true }
        let joins = (try? context.fetch(FetchDescriptor<JournalTemplateGroup>(predicate: predicate))) ?? []
        let groupIds = Set(joins.compactMap { $0.templateGroupId })
        return fetchActiveGroups(libraryId: libraryId, in: context).filter { group in
            guard let groupId = group.templateGroupId else { return false }
            return groupIds.contains(groupId)
        }
    }

    // MARK: - Picker scoping

    static func templatesForPicker(scope: PickerScope, libraryId: UUID, in context: ModelContext) -> [NoteTemplate] {
        let groups: [TemplateGroup]
        switch scope {
        case .notebook(let notebookId):
            groups = templateGroups(forNotebook: notebookId, libraryId: libraryId, in: context)
        case .journal:
            groups = templateGroups(forJournalLibraryId: libraryId, in: context)
        case .library:
            return fetchActiveTemplates(libraryId: libraryId, in: context)
        }

        let groupIds = Set(groups.compactMap { $0.templateGroupId })
        return fetchActiveTemplates(libraryId: libraryId, in: context).filter { template in
            guard let templateGroupId = template.templateGroupId else { return false }
            return groupIds.contains(templateGroupId)
        }
    }

    // MARK: - Apply

    /// Weaves every field's default value into `content`'s frontmatter — pure, mirrors
    /// `PropertyParser`'s style. Later fields win if two somehow share a name (shouldn't
    /// happen: a template's own fields are keyed by name). `content` may be a `bodyTemplate`
    /// scaffold — `PropertyParser.applying` keeps the frontmatter block at the top and the
    /// body below it.
    static func applying(_ template: NoteTemplate, to content: String) -> String {
        template.fields.reduce(content) { partial, field in
            PropertyParser.applying(key: field.name, value: field.defaultValue, valueType: field.valueType, to: partial)
        }
    }

    /// Apply-at-creation: creates a new `Document` pre-filled with `template`'s fields **and**
    /// its `bodyTemplate` scaffold (or a blank document if `template` is `nil` — the picker's
    /// explicit "start blank" option). Properties are indexed immediately, and — so a template
    /// checklist is live without waiting for the first manual save — blocks and tasks are
    /// reconciled here too (`DocumentDAL.create` already splits blocks; this adds the task pass).
    @discardableResult
    static func createDocument(from template: NoteTemplate?, title: String, libraryId: UUID, in context: ModelContext) -> Document {
        let content = template.map { applying($0, to: $0.bodyTemplate ?? "") } ?? ""
        let document = DocumentDAL.create(title: title, content: content, libraryId: libraryId, in: context)
        if let documentId = document.documentId {
            PropertyDAL.syncProperties(for: documentId, content: content, libraryId: libraryId, in: context)
            _ = TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)
        }
        return document
    }

    /// Apply-after-the-fact: backfills only the fields `document` doesn't already have a
    /// Property value for — never overwrites an existing value, per Journey 6's "backfilling
    /// Properties without re-creating the Document" (retroactively applying a template should
    /// never clobber what the user already filled in by hand).
    ///
    /// Deliberately **fields-only**: a template's `bodyTemplate` is never injected into an
    /// existing document here — that would clobber or duplicate the user's own prose. "Insert
    /// this template's body" is a separate, explicit editor action (not built in v1).
    static func applyRetroactively(_ template: NoteTemplate, to document: Document, in context: ModelContext) {
        guard let libraryId = document.libraryId else { return }
        let existingContent = document.content ?? ""
        let existingKeys = Set(PropertyParser.extractFrontmatterProperties(from: existingContent).map { $0.key })

        let missingFields = template.fields.filter { !existingKeys.contains($0.name) }
        guard !missingFields.isEmpty else { return }

        let updatedContent = missingFields.reduce(existingContent) { partial, field in
            PropertyParser.applying(key: field.name, value: field.defaultValue, valueType: field.valueType, to: partial)
        }

        DocumentDAL.updateContent(document, content: updatedContent, in: context)
        if let documentId = document.documentId {
            PropertyDAL.syncProperties(for: documentId, content: updatedContent, libraryId: libraryId, in: context)
        }
    }

    // MARK: - Starter content

    /// The bundled packs auto-seeded into every newly-created library (per
    /// NoteBytez20260824v1-Templates.md G16). The 16 knowledge-management packs are opt-in via
    /// the Template Gallery / first-run onboarding — only these three creative starters are
    /// seeded unprompted, preserving the pre-existing new-library experience.
    static let starterPackIds = ["fiction-writing", "wedding-planning", "photography-client-work"]

    /// Materializes the starter packs into a newly-created library from the bundled
    /// `TemplatePacks.json` resource — one code path with the Gallery (`TemplatePackDAL`).
    /// Idempotent: a library that already has any `TemplateGroup` is left untouched, so this is
    /// safe to call more than once and never duplicates content.
    static func seedStarterContent(libraryId: UUID, in context: ModelContext, bundle: Bundle = .main) {
        guard fetchActiveGroups(libraryId: libraryId, in: context).isEmpty else { return }

        for packId in starterPackIds {
            TemplatePackDAL.addPack(id: packId, libraryId: libraryId, bundle: bundle, in: context)
        }
    }

}
