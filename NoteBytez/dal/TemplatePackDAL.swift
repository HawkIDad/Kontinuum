// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplatePackDAL.swift
//  NoteBytez
//

import Foundation
import OSLog
import SwiftData

/// Reads bundled Template Packs and materializes them into a library as ordinary editable
/// `TemplateGroup`/`NoteTemplate` rows, and computes/applies non-destructive pack updates.
/// Per NoteBytez20260824v1-Templates.md, Phase 1.
///
/// Localized at add-time (NoteBytez20260823v2-MultiLanguage.md Phase 4 / decision G2): every
/// pack literal materialized here is resolved through the String Catalog via `localizedSeedString`
/// before it's written to the row, then never touched again — from that point on it's the user's
/// ordinary, editable data. Only the 3 starter packs (`TemplateDAL.starterPackIds`) have real
/// non-English catalog entries today; the other 17 Gallery packs resolve to their own English
/// literal (the same value they'd have carried unlocalized) until a later rollout phase adds
/// their translations — an untranslated key is not an error, it's `String(localized:)`'s normal
/// fallback-to-source behavior.
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
    static func addPack(_ definition: TemplatePackDefinition, libraryId: UUID, locale: Locale = .current, in context: ModelContext) -> AddResult {
        guard !addedPackIds(libraryId: libraryId, in: context).contains(definition.packId) else {
            return .alreadyAdded
        }

        let group = TemplateGroup(
            name: localizedSeedString(definition.displayName, locale: locale), libraryId: libraryId,
            sourcePackId: definition.packId, sourcePackVersion: definition.version
        )
        context.insert(group)
        SyncEngine.shared.recordChanged(group, in: context)

        if let groupId = group.templateGroupId {
            for template in definition.templates {
                TemplateDAL.createTemplate(
                    name: localizedSeedString(template.name, locale: locale), templateGroupId: groupId, libraryId: libraryId,
                    fields: localizedSeedFields(template.noteTemplateFields, locale: locale),
                    bodyTemplate: template.bodyTemplate.map { localizedSeedString($0, locale: locale) }, in: context
                )
            }
        }
        return .added(group)
    }

    @discardableResult
    static func addPack(id packId: String, libraryId: UUID, bundle: Bundle = .main, locale: Locale = .current, in context: ModelContext) -> AddResult {
        guard let definition = pack(withId: packId, bundle: bundle) else { return .notFound }
        return addPack(definition, libraryId: libraryId, locale: locale, in: context)
    }

    // MARK: - Seed-time localization

    /// Resolves one bundled pack literal through the String Catalog at the moment it's
    /// materialized. `raw` doubles as its own catalog key (same convention as
    /// `Text(LocalizedStringKey(pack.displayName))` in `TemplatePackPreviewView`) — an empty
    /// string or an untranslated key both fall back to `raw` itself, so this is a no-op until a
    /// locale actually has a translation for it.
    ///
    /// Deliberately goes through `LocalizedStringResource`, not `String(localized:locale:)`
    /// directly — the latter silently ignores its own `locale:` argument and resolves against
    /// the process's ambient current locale instead. See
    /// `Docs/Localization/TechnicalNotes.md` for the full empirical writeup (this is easy to
    /// reintroduce by "simplifying" back to the more obvious-looking API).
    private static func localizedSeedString(_ raw: String, locale: Locale) -> String {
        guard !raw.isEmpty else { return raw }
        let resource = LocalizedStringResource(String.LocalizationValue(raw), locale: locale)
        return String(localized: resource)
    }

    /// Field *names* are always localized (they're short labels, like a template's own name).
    /// A field's `defaultValue` is only localized when it's descriptive text a `.text` field
    /// seeds with a real word (e.g. a Status field defaulting to "Drafting") — a `.checkbox`
    /// default ("true"/"false") and a `.date`/`.number` default are canonical, machine-readable
    /// tokens (the same register as `DoNotTranslate.md`'s frontmatter values), never words.
    private static func localizedSeedFields(_ fields: [NoteTemplateField], locale: Locale) -> [NoteTemplateField] {
        fields.map { field in
            NoteTemplateField(
                name: localizedSeedString(field.name, locale: locale),
                valueType: field.valueType,
                defaultValue: field.valueType == .text ? localizedSeedString(field.defaultValue, locale: locale) : field.defaultValue
            )
        }
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
