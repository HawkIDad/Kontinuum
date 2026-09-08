// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// Serves both S18 sub-flows — the Template Picker and the Template Manager — rather than two
/// view models, the same rationale `SearchViewModel` used for S6/S7 (same library, same
/// template concept).
@Observable
final class TemplateViewModel {

    struct PickerSection: Identifiable {
        let group: TemplateGroup
        let templates: [NoteTemplate]
        var id: UUID { group.templateGroupId ?? UUID() }
    }

    private(set) var groups: [TemplateGroup] = []

    private let libraryId: UUID
    private let modelContext: ModelContext

    init(libraryId: UUID, modelContext: ModelContext) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        self.load()
    }

    func load() {
        groups = TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: modelContext)
    }

    // MARK: - Manager

    func templates(in group: TemplateGroup) -> [NoteTemplate] {
        guard let groupId = group.templateGroupId else { return [] }
        return TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: modelContext)
    }

    func createGroup(name: String) {
        TemplateDAL.createGroup(name: name, libraryId: libraryId, in: modelContext)
        load()
    }

    func deleteGroup(_ group: TemplateGroup) {
        TemplateDAL.deleteGroup(group, in: modelContext)
        load()
    }

    @discardableResult
    func createTemplate(name: String, in group: TemplateGroup) -> NoteTemplate? {
        guard let groupId = group.templateGroupId else { return nil }
        return TemplateDAL.createTemplate(name: name, templateGroupId: groupId, libraryId: libraryId, in: modelContext)
    }

    func deleteTemplate(_ template: NoteTemplate) {
        TemplateDAL.deleteTemplate(template, in: modelContext)
    }

    func updateFields(_ template: NoteTemplate, fields: [NoteTemplateField]) {
        TemplateDAL.updateFields(template, fields: fields, in: modelContext)
    }

    // MARK: - Picker

    /// Every non-empty group for `scope`, in the same order as `groups`, paired with its
    /// templates — the Picker's section list.
    func pickerSections(scope: TemplateDAL.PickerScope) -> [PickerSection] {
        let templates = TemplateDAL.templatesForPicker(scope: scope, libraryId: libraryId, in: modelContext)
        let templatesByGroupId = Dictionary(grouping: templates, by: { $0.templateGroupId })

        return groups.compactMap { group in
            guard let groupId = group.templateGroupId,
                  let groupTemplates = templatesByGroupId[groupId], !groupTemplates.isEmpty else { return nil }
            return PickerSection(group: group, templates: groupTemplates)
        }
    }

}
