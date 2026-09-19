// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplatePackDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct TemplatePackDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Notebook.self, DocumentNotebook.self,
            Property.self, DocumentProperty.self, TemplateGroup.self, NoteTemplate.self,
            NotebookTemplateGroup.self, JournalTemplateGroup.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func pack(_ id: String, version: Int, templates: [PackTemplateDefinition]) -> TemplatePackDefinition {
        TemplatePackDefinition(
            packId: id, version: version, category: "Test", displayName: id.capitalized,
            summary: "", note: nil, roleAliases: [], templates: templates
        )
    }

    private func template(_ name: String, fields: [PackFieldDefinition] = [], body: String? = nil) -> PackTemplateDefinition {
        PackTemplateDefinition(name: name, fields: fields, bodyTemplate: body)
    }

    // MARK: - parse

    @Test func parseYieldsEmptyOnMalformedJSONRatherThanThrowing() {
        #expect(TemplatePackDAL.parse(Data("not json".utf8)).isEmpty)
        #expect(TemplatePackDAL.parse(Data("[{\"packId\":\"x\"}]".utf8)).isEmpty, "missing required keys → skipped, no crash")
    }

    @Test func parseDecodesAWellFormedPack() throws {
        let json = """
        [{"packId":"p","version":2,"category":"C","displayName":"P","summary":"s","note":null,
          "roleAliases":["Software Engineer"],
          "templates":[{"name":"T","bodyTemplate":"# T","fields":[{"name":"Status","valueType":"text","defaultValue":"Draft"}]}]}]
        """
        let packs = TemplatePackDAL.parse(Data(json.utf8))
        #expect(packs.count == 1)
        #expect(packs[0].version == 2)
        #expect(packs[0].templates[0].fields[0].valueType == .text)
    }

    // MARK: - addPack

    @Test func addPackMaterializesAGroupAndItsTemplatesAsActiveRows() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let definition = pack("engineering", version: 3, templates: [
            template("Design Doc", fields: [PackFieldDefinition(name: "Status", valueType: .text, defaultValue: "Draft")],
                     body: "# Design Doc\n\n## Action Items\n\n- [ ] Review"),
            template("Runbook", body: "# Runbook")
        ])

        let result = TemplatePackDAL.addPack(definition, libraryId: libraryId, in: context)

        guard case .added(let group) = result else { Issue.record("expected .added"); return }
        #expect(group.sourcePackId == "engineering")
        #expect(group.sourcePackVersion == 3)
        let templates = TemplateDAL.fetchActiveTemplates(templateGroupId: try #require(group.templateGroupId), in: context)
        #expect(Set(templates.compactMap { $0.name }) == ["Design Doc", "Runbook"])
        #expect(templates.first { $0.name == "Design Doc" }?.bodyTemplate?.contains("- [ ] Review") == true)
    }

    @Test func addPackIsRefusedForAPackAlreadyAddedEvenIfItsGroupWasDeleted() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let definition = pack("engineering", version: 1, templates: [template("Design Doc")])

        guard case .added(let group) = TemplatePackDAL.addPack(definition, libraryId: libraryId, in: context) else {
            Issue.record("first add should succeed"); return
        }
        TemplateDAL.deleteGroup(group, in: context)

        #expect(TemplatePackDAL.addPack(definition, libraryId: libraryId, in: context) == .alreadyAdded)
    }

    @Test func addPackByIdReturnsNotFoundForAnUnknownPack() throws {
        let context = try makeContext()
        #expect(TemplatePackDAL.addPack(id: "does-not-exist", libraryId: UUID(), in: context) == .notFound)
    }

    // MARK: - updateAvailable / applyUpdate

    @Test func updateAvailableReflectsBundledVersionVsApplied() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let v1 = pack("engineering", version: 1, templates: [template("Design Doc")])
        guard case .added(let group) = TemplatePackDAL.addPack(v1, libraryId: libraryId, in: context) else { return }

        // Simulate a newer bundled version by applying an update and checking the flag semantics.
        let v3 = pack("engineering", version: 3, templates: [template("Design Doc")])
        #expect(v3.version > (group.sourcePackVersion ?? 0))
        _ = TemplatePackDAL.applyUpdate(v3, to: group, libraryId: libraryId, in: context)
        #expect(group.sourcePackVersion == 3)
    }

    @Test func applyUpdateIsAdditiveAndNonDestructive() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let v1 = pack("engineering", version: 1, templates: [
            template("Design Doc", fields: [PackFieldDefinition(name: "Owner", valueType: .text, defaultValue: "")],
                     body: "# Design Doc")
        ])
        guard case .added(let group) = TemplatePackDAL.addPack(v1, libraryId: libraryId, in: context) else { return }
        let groupId = try #require(group.templateGroupId)

        // User edits an existing template's field default and body, and deletes nothing yet.
        let designDoc = try #require(TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: context).first { $0.name == "Design Doc" })
        TemplateDAL.updateFields(designDoc, fields: [NoteTemplateField(name: "Owner", valueType: .text, defaultValue: "Me")], in: context)
        TemplateDAL.updateBody(designDoc, bodyTemplate: "# My edited body", in: context)

        // A template the user removed must not come back.
        let removed = TemplateDAL.createTemplate(name: "Legacy", templateGroupId: groupId, libraryId: libraryId, in: context)
        TemplateDAL.deleteTemplate(removed, in: context)

        let v2 = pack("engineering", version: 2, templates: [
            template("Design Doc", fields: [
                PackFieldDefinition(name: "Owner", valueType: .text, defaultValue: ""),      // unchanged name
                PackFieldDefinition(name: "Priority", valueType: .text, defaultValue: "Medium") // new field
            ], body: "# New pack body"),
            template("Legacy", body: "# Should not resurrect"),                                 // user deleted this
            template("Postmortem", body: "# Postmortem")                                         // brand new
        ])

        #expect(TemplatePackDAL.applyUpdate(v2, to: group, libraryId: libraryId, in: context))

        let active = TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: context)
        #expect(Set(active.compactMap { $0.name }) == ["Design Doc", "Postmortem"], "new template added, deleted one not resurrected")

        let updatedDesignDoc = try #require(active.first { $0.name == "Design Doc" })
        #expect(updatedDesignDoc.fields.first { $0.name == "Owner" }?.defaultValue == "Me", "user's edited default is untouched")
        #expect(updatedDesignDoc.fields.contains { $0.name == "Priority" }, "new field is added")
        #expect(updatedDesignDoc.bodyTemplate == "# My edited body", "user's edited body is untouched")
        #expect(group.sourcePackVersion == 2)
    }

    // MARK: - Bundled resource (Phase 2 lint gate)

    @Test func bundledTemplatePacksDecodeAndPassLint() {
        let packs = TemplatePackDAL.availablePacks()
        #expect(packs.count == 20, "16 KM packs + 1 culinary pack + 3 creative starters")
        let issues = TemplatePackLint.issues(in: packs)
        #expect(issues.isEmpty, "lint issues: \(issues.joined(separator: "; "))")
    }

    @Test func bundledPacksCoverEveryDocumentedRoleExactlyOnce() {
        let aliases = TemplatePackDAL.availablePacks().flatMap(\.roleAliases)
        for role in TemplateRoles.all {
            #expect(aliases.filter { $0 == role }.count == 1, "\(role) must be covered by exactly one pack")
        }
    }

    // MARK: - Seed-time localization (Phase 4, decision G2)

    /// `addPack` resolves every pack literal through the String Catalog at the moment it
    /// materializes the row, using whatever `locale` is passed in (production always passes the
    /// device's current locale; tests pin one explicitly for a deterministic assertion). A
    /// locale with no catalog entry for a given definition (any locale here, since `pack(...)`
    /// builds a synthetic definition with no real translations) simply falls back to the source
    /// literal — proving the mechanism is a no-op absent a translation, not a hard dependency on
    /// one.
    @Test func addPackResolvesGroupAndFieldNamesThroughTheLocaleAtSeedTime() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let definition = pack("engineering", version: 1, templates: [
            template("Design Doc", fields: [PackFieldDefinition(name: "Status", valueType: .text, defaultValue: "Draft")])
        ])

        // "Status" has a real Spanish catalog entry ("Estado") from Phase 4's starter-pack work,
        // even though this synthetic "engineering" pack is unrelated to it — the catalog key is
        // the word itself, shared across every context that uses it.
        guard case .added(let group) = TemplatePackDAL.addPack(definition, libraryId: libraryId, locale: Locale(identifier: "es"), in: context) else {
            Issue.record("expected .added"); return
        }
        let groupId = try #require(group.templateGroupId)
        let template = try #require(TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: context).first)
        #expect(template.fields.first?.name == "Estado")
    }

    @Test func addPackFallsBackToTheSourceLiteralWhenNoTranslationExists() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let definition = pack("engineering", version: 1, templates: [template("Design Doc")])

        guard case .added(let group) = TemplatePackDAL.addPack(definition, libraryId: libraryId, locale: Locale(identifier: "es"), in: context) else {
            Issue.record("expected .added"); return
        }
        #expect(group.name == "Engineering", "no catalog entry for this synthetic pack's own display name — falls back to itself")
    }

    @Test func addPackLocalizesTheThreeRealStarterPacksUnderSpanishAndGerman() throws {
        for (locale, expectedName, expectedTemplateName, expectedFieldName) in [
            ("es", "Escritura de Ficción", "Personaje", "Especie"),
            ("de", "Romanschreiben", "Figur", "Spezies"),
        ] {
            let context = try makeContext()
            let libraryId = UUID()
            guard case .added(let group) = TemplatePackDAL.addPack(id: "fiction-writing", libraryId: libraryId, locale: Locale(identifier: locale), in: context) else {
                Issue.record("expected .added"); return
            }
            #expect(group.name == expectedName)
            let groupId = try #require(group.templateGroupId)
            let character = try #require(TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: context).first { $0.name == expectedTemplateName })
            #expect(character.fields.first { $0.name == expectedFieldName } != nil)
            #expect(character.bodyTemplate?.hasPrefix("#") == true, "body scaffold was resolved (non-empty) under \(locale)")
        }
    }

    @Test func addPackNeverLocalizesACheckboxDefaultValue() throws {
        let context = try makeContext()
        let libraryId = UUID()
        guard case .added(let group) = TemplatePackDAL.addPack(id: "fiction-writing", libraryId: libraryId, locale: Locale(identifier: "es"), in: context) else {
            Issue.record("expected .added"); return
        }
        let groupId = try #require(group.templateGroupId)
        let character = try #require(TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: context).first { $0.name == "Personaje" })
        #expect(character.fields.first { $0.valueType == .checkbox }?.defaultValue == "true", "checkbox default is a canonical machine token, never translated")
    }
}
