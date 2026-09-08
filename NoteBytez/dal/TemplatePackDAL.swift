// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplatePackDAL.swift
//  Kontinuum
//

import Foundation
import OSLog
import SwiftData

/// Reads bundled Template Packs and materializes them into a library as ordinary editable
/// `TemplateGroup`/`NoteTemplate` rows, and computes/applies non-destructive pack updates.
/// Per NoteBytez20260824v1-Templates.md, Phase 1.
///
/// English-only for now: pack resources carry literal strings. When multi-language support
/// resumes (that plan's Phase 6), the literals become String Catalog keys resolved via
/// `String(localized:)` here at add-time.
enum TemplatePackDAL {

    static let bundledResourceName = "TemplatePacks"

    // MARK: - Reading bundled packs

    /// Parses a pack-array JSON payload. A malformed payload logs and yields `[]` rather than
    /// throwing — a bad resource must not crash the app.
    static func parse(_ data: Data) -> [TemplatePackDefinition] {
        do {
            return try JSONDecoder().decode([TemplatePackDefinition].self, from: data)
        } catch {
            Log.logger(.data).error("TemplatePacks resource failed to decode: \(String(describing: error), privacy: .public)")
            return []
        }
    }

    static func availablePacks(bundle: Bundle = .main) -> [TemplatePackDefinition] {
        guard let url = bundle.url(forResource: bundledResourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            Log.logger(.data).error("\(bundledResourceName).json not found in bundle")
            return []
        }
        return parse(data)
    }

    static func pack(withId packId: String, bundle: Bundle = .main) -> TemplatePackDefinition? {
        availablePacks(bundle: bundle).first { $0.packId == packId }
    }

    // MARK: - Added-pack introspection

    /// Every `TemplateGroup` in the library that was materialized from a bundled pack —
    /// **including soft-deleted ones**, so re-adding a pack the user removed is still refused.
    static func addedPackGroups(libraryId: UUID, in context: ModelContext) -> [TemplateGroup] {
        let predicate = #Predicate<TemplateGroup> { $0.libraryId == libraryId && $0.sourcePackId != nil }
        return (try? context.fetch(FetchDescriptor<TemplateGroup>(predicate: predicate))) ?? []
    }

    static func addedPackIds(libraryId: UUID, in context: ModelContext) -> Set<String> {
        Set(addedPackGroups(libraryId: libraryId, in: context).compactMap { $0.sourcePackId })
    }

    // MARK: - Add

    enum AddResult: Equatable {
        case added(TemplateGroup)
        case alreadyAdded
        case notFound
    }

    @discardableResult
    static func addPack(_ definition: TemplatePackDefinition, libraryId: UUID, in context: ModelContext) -> AddResult {
        guard !addedPackIds(libraryId: libraryId, in: context).contains(definition.packId) else {
            return .alreadyAdded
        }

        let group = TemplateGroup(
            name: definition.displayName, libraryId: libraryId,
            sourcePackId: definition.packId, sourcePackVersion: definition.version
        )
        context.insert(group)
        SyncEngine.shared.recordChanged(group, in: context)

        if let groupId = group.templateGroupId {
            for template in definition.templates {
                TemplateDAL.createTemplate(
                    name: template.name, templateGroupId: groupId, libraryId: libraryId,
                    fields: template.noteTemplateFields, bodyTemplate: template.bodyTemplate, in: context
                )
            }
        }
        return .added(group)
    }

    @discardableResult
    static func addPack(id packId: String, libraryId: UUID, bundle: Bundle = .main, in context: ModelContext) -> AddResult {
        guard let definition = pack(withId: packId, bundle: bundle) else { return .notFound }
        return addPack(definition, libraryId: libraryId, in: context)
    }

    // MARK: - Update

    /// True iff a bundled pack exists for `group.sourcePackId` with a higher `version` than the
    /// one applied to this group.
    static func updateAvailable(for group: TemplateGroup, bundle: Bundle = .main) -> Bool {
        guard let packId = group.sourcePackId, let applied = group.sourcePackVersion,
              let definition = pack(withId: packId, bundle: bundle) else { return false }
        return definition.version > applied
    }

    /// Non-destructive update. Adds templates whose name isn't already in the group (active
    /// **or** soft-deleted — a user-removed template is not resurrected), and adds fields whose
    /// name isn't already on a name-matched active template. Fills an empty body from the pack.
    /// Never edits an existing field's `defaultValue`/`valueType` or a non-empty body. Bumps
    /// `group.sourcePackVersion` to the bundled version.
    @discardableResult
    static func applyUpdate(_ definition: TemplatePackDefinition, to group: TemplateGroup, libraryId: UUID, in context: ModelContext) -> Bool {
        guard let groupId = group.templateGroupId, group.sourcePackId == definition.packId else { return false }

        let existingPredicate = #Predicate<NoteTemplate> { $0.templateGroupId == groupId }
        let existing = (try? context.fetch(FetchDescriptor<NoteTemplate>(predicate: existingPredicate))) ?? []
        let existingNames = Set(existing.compactMap { $0.name })

        for packTemplate in definition.templates {
            if let active = existing.first(where: { $0.name == packTemplate.name && $0.isActive == true }) {
                let currentFieldNames = Set(active.fields.map(\.name))
                let newFields = packTemplate.noteTemplateFields.filter { !currentFieldNames.contains($0.name) }
                if !newFields.isEmpty {
                    TemplateDAL.updateFields(active, fields: active.fields + newFields, in: context)
                }
                if (active.bodyTemplate ?? "").isEmpty, let packBody = packTemplate.bodyTemplate, !packBody.isEmpty {
                    TemplateDAL.updateBody(active, bodyTemplate: packBody, in: context)
                }
            } else if !existingNames.contains(packTemplate.name) {
                TemplateDAL.createTemplate(
                    name: packTemplate.name, templateGroupId: groupId, libraryId: libraryId,
                    fields: packTemplate.noteTemplateFields, bodyTemplate: packTemplate.bodyTemplate, in: context
                )
            }
            // else: a soft-deleted template with this name exists → do not resurrect it.
        }

        group.sourcePackVersion = definition.version
        group.updatedOn = Date()
        SyncEngine.shared.recordChanged(group, in: context)
        return true
    }

    @discardableResult
    static func applyUpdate(to group: TemplateGroup, libraryId: UUID, bundle: Bundle = .main, in context: ModelContext) -> Bool {
        guard let packId = group.sourcePackId, let definition = pack(withId: packId, bundle: bundle) else { return false }
        return applyUpdate(definition, to: group, libraryId: libraryId, in: context)
    }
}
