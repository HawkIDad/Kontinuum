// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct TemplateDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Notebook.self, DocumentNotebook.self,
            Property.self, DocumentProperty.self, TemplateGroup.self, NoteTemplate.self,
            NotebookTemplateGroup.self, JournalTemplateGroup.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - TemplateGroup / NoteTemplate CRUD

    @Test func createGroupAndTemplateAreFetchable() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let groupId = try #require(group.templateGroupId)
        TemplateDAL.createTemplate(name: "Character", templateGroupId: groupId, libraryId: libraryId, in: context)

        #expect(TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context).count == 1)
        #expect(TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: context).count == 1)
    }

    @Test func renameGroupUpdatesName() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)

        TemplateDAL.renameGroup(group, to: "Sci-Fi Worldbuilding", in: context)

        #expect(group.name == "Sci-Fi Worldbuilding")
    }

    @Test func deleteGroupCascadesToItsTemplatesAndJoins() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let notebookId = UUID()
        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let groupId = try #require(group.templateGroupId)
        TemplateDAL.createTemplate(name: "Character", templateGroupId: groupId, libraryId: libraryId, in: context)
        TemplateDAL.attachToNotebook(templateGroupId: groupId, notebookId: notebookId, libraryId: libraryId, in: context)
        TemplateDAL.attachToJournal(templateGroupId: groupId, libraryId: libraryId, in: context)

        TemplateDAL.deleteGroup(group, in: context)

        #expect(TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context).isEmpty)
        #expect(TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: context).isEmpty)
        #expect(TemplateDAL.templateGroups(forNotebook: notebookId, libraryId: libraryId, in: context).isEmpty)
        #expect(TemplateDAL.templateGroups(forJournalLibraryId: libraryId, in: context).isEmpty)
    }

    @Test func updateFieldsPersistsTheFieldList() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let template = TemplateDAL.createTemplate(name: "Character", templateGroupId: try #require(group.templateGroupId), libraryId: libraryId, in: context)

        TemplateDAL.updateFields(template, fields: [
            NoteTemplateField(name: "Species", valueType: .text, defaultValue: ""),
            NoteTemplateField(name: "Alive", valueType: .checkbox, defaultValue: "true")
        ], in: context)

        #expect(template.fields.count == 2)
        #expect(template.fields.first?.name == "Species")
        #expect(template.fields.last?.valueType == .checkbox)
    }

    @Test func deleteTemplateSoftDeletesWithoutAffectingItsGroup() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let groupId = try #require(group.templateGroupId)
        let template = TemplateDAL.createTemplate(name: "Character", templateGroupId: groupId, libraryId: libraryId, in: context)

        TemplateDAL.deleteTemplate(template, in: context)

        #expect(TemplateDAL.fetchActiveTemplates(templateGroupId: groupId, in: context).isEmpty)
        #expect(TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context).count == 1)
    }

    // MARK: - Notebook/Journal join attach/detach

    @Test func attachToNotebookIsIdempotentAndReactivatesADetachedJoin() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let notebookId = UUID()
        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let groupId = try #require(group.templateGroupId)

        TemplateDAL.attachToNotebook(templateGroupId: groupId, notebookId: notebookId, libraryId: libraryId, in: context)
        TemplateDAL.attachToNotebook(templateGroupId: groupId, notebookId: notebookId, libraryId: libraryId, in: context)
        #expect(TemplateDAL.templateGroups(forNotebook: notebookId, libraryId: libraryId, in: context).count == 1)

        TemplateDAL.detachFromNotebook(templateGroupId: groupId, notebookId: notebookId, in: context)
        #expect(TemplateDAL.templateGroups(forNotebook: notebookId, libraryId: libraryId, in: context).isEmpty)

        TemplateDAL.attachToNotebook(templateGroupId: groupId, notebookId: notebookId, libraryId: libraryId, in: context)
        #expect(TemplateDAL.templateGroups(forNotebook: notebookId, libraryId: libraryId, in: context).count == 1)
    }

    @Test func attachToJournalIsIdempotentAndReactivatesADetachedJoin() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let groupId = try #require(group.templateGroupId)

        TemplateDAL.attachToJournal(templateGroupId: groupId, libraryId: libraryId, in: context)
        TemplateDAL.attachToJournal(templateGroupId: groupId, libraryId: libraryId, in: context)
        #expect(TemplateDAL.templateGroups(forJournalLibraryId: libraryId, in: context).count == 1)

        TemplateDAL.detachFromJournal(templateGroupId: groupId, libraryId: libraryId, in: context)
        #expect(TemplateDAL.templateGroups(forJournalLibraryId: libraryId, in: context).isEmpty)
    }

    // MARK: - Picker scoping

    @Test func templatesForPickerScopedToNotebookReturnsOnlyThatNotebooksGroups() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let notebookId = UUID()

        let attachedGroup = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let attachedGroupId = try #require(attachedGroup.templateGroupId)
        TemplateDAL.createTemplate(name: "Character", templateGroupId: attachedGroupId, libraryId: libraryId, in: context)
        TemplateDAL.attachToNotebook(templateGroupId: attachedGroupId, notebookId: notebookId, libraryId: libraryId, in: context)

        let unattachedGroup = TemplateDAL.createGroup(name: "Wedding Planning", libraryId: libraryId, in: context)
        TemplateDAL.createTemplate(name: "Vendor", templateGroupId: try #require(unattachedGroup.templateGroupId), libraryId: libraryId, in: context)

        let templates = TemplateDAL.templatesForPicker(scope: .notebook(notebookId), libraryId: libraryId, in: context)

        #expect(templates.count == 1)
        #expect(templates.first?.name == "Character")
    }

    @Test func templatesForPickerScopedToJournalReturnsOnlyAttachedJournalGroups() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let attachedGroup = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let attachedGroupId = try #require(attachedGroup.templateGroupId)
        TemplateDAL.createTemplate(name: "Morning Pages", templateGroupId: attachedGroupId, libraryId: libraryId, in: context)
        TemplateDAL.attachToJournal(templateGroupId: attachedGroupId, libraryId: libraryId, in: context)

        let unattachedGroup = TemplateDAL.createGroup(name: "Wedding Planning", libraryId: libraryId, in: context)
        TemplateDAL.createTemplate(name: "Vendor", templateGroupId: try #require(unattachedGroup.templateGroupId), libraryId: libraryId, in: context)

        let templates = TemplateDAL.templatesForPicker(scope: .journal, libraryId: libraryId, in: context)

        #expect(templates.count == 1)
        #expect(templates.first?.name == "Morning Pages")
    }

    @Test func templatesForPickerScopedToLibraryReturnsEveryTemplateUngrouped() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let groupOne = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        TemplateDAL.createTemplate(name: "Character", templateGroupId: try #require(groupOne.templateGroupId), libraryId: libraryId, in: context)
        let groupTwo = TemplateDAL.createGroup(name: "Wedding Planning", libraryId: libraryId, in: context)
        TemplateDAL.createTemplate(name: "Vendor", templateGroupId: try #require(groupTwo.templateGroupId), libraryId: libraryId, in: context)

        let templates = TemplateDAL.templatesForPicker(scope: .library, libraryId: libraryId, in: context)

        #expect(templates.count == 2)
    }

    // MARK: - Apply-at-creation

    @Test func createDocumentFromTemplatePreFillsAndIndexesProperties() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let template = TemplateDAL.createTemplate(name: "Character", templateGroupId: try #require(group.templateGroupId), libraryId: libraryId, fields: [
            NoteTemplateField(name: "Species", valueType: .text, defaultValue: "Kethran"),
            NoteTemplateField(name: "Alive", valueType: .checkbox, defaultValue: "true")
        ], in: context)

        let document = TemplateDAL.createDocument(from: template, title: "Elyra Voss", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        #expect(document.content?.contains("Species: \"Kethran\"") == true)
        let properties = PropertyDAL.fetchProperties(for: documentId, in: context)
        #expect(properties.count == 2)
        #expect(properties.first { $0.property.name == "Species" }?.value == "Kethran")
    }

    @Test func createDocumentWithNoTemplateProducesABlankDocument() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let document = TemplateDAL.createDocument(from: nil, title: "Untitled", libraryId: libraryId, in: context)

        #expect(document.content == "")
        #expect(PropertyDAL.fetchProperties(for: try #require(document.documentId), in: context).isEmpty)
    }

    // MARK: - Body templates (NoteBytez20260824v1 Phase 0)

    @Test func createDocumentFromTemplateWeavesFrontmatterAboveTheBodyScaffold() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let group = TemplateDAL.createGroup(name: "Software Engineering", libraryId: libraryId, in: context)
        let body = "# Overview\n\nWhat is being decided.\n\n## Action Items\n\n- [ ] Circulate for review\n- [ ] Record the decision"
        let template = TemplateDAL.createTemplate(
            name: "Design Doc", templateGroupId: try #require(group.templateGroupId), libraryId: libraryId,
            fields: [NoteTemplateField(name: "Status", valueType: .text, defaultValue: "Draft")],
            bodyTemplate: body, in: context
        )

        let document = TemplateDAL.createDocument(from: template, title: "Sync engine v2", libraryId: libraryId, in: context)
        let content = try #require(document.content)

        #expect(content.hasPrefix("---\n"), "frontmatter block sits at the top")
        #expect(content.contains("Status: \"Draft\""))
        #expect(content.contains("# Overview"))
        #expect(content.range(of: "Status: \"Draft\"")!.lowerBound < content.range(of: "# Overview")!.lowerBound)
    }

    @Test func createDocumentFromTemplateIndexesBodyTasksImmediately() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let group = TemplateDAL.createGroup(name: "Common", libraryId: libraryId, in: context)
        let template = TemplateDAL.createTemplate(
            name: "Meeting Notes", templateGroupId: try #require(group.templateGroupId), libraryId: libraryId,
            fields: [], bodyTemplate: "## Notes\n\n## Action Items\n\n- [ ] Send recap\n- [ ] Book follow-up",
            in: context
        )

        let document = TemplateDAL.createDocument(from: template, title: "Kickoff", libraryId: libraryId, in: context)
        let tasks = TaskDAL.fetchActive(documentId: try #require(document.documentId), in: context)

        #expect(tasks.count == 2, "template checklist items are live TaskItems without a manual save")
        #expect(document.content?.contains("- [ ] Send recap") == true, "task lines remain literal Markdown")
    }

    @Test func applyRetroactivelyNeverInjectsTheBodyTemplate() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Existing", content: "---\nStatus: \"Active\"\n---\nMy own prose.", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        PropertyDAL.syncProperties(for: documentId, content: try #require(document.content), libraryId: libraryId, in: context)

        let group = TemplateDAL.createGroup(name: "Software Engineering", libraryId: libraryId, in: context)
        let template = TemplateDAL.createTemplate(
            name: "Design Doc", templateGroupId: try #require(group.templateGroupId), libraryId: libraryId,
            fields: [NoteTemplateField(name: "Owner", valueType: .text, defaultValue: "")],
            bodyTemplate: "# Overview\n\n## Action Items\n\n- [ ] Do not inject me", in: context
        )

        TemplateDAL.applyRetroactively(template, to: document, in: context)
        let content = try #require(document.content)

        #expect(content.contains("My own prose."))
        #expect(content.contains("Owner:"), "missing field is still backfilled")
        #expect(!content.contains("# Overview"), "the body scaffold must not be injected")
        #expect(!content.contains("Do not inject me"))
    }

    @Test func noteTemplateBodyTemplateRoundTripsThroughCodable() throws {
        let original = NoteTemplate(name: "Runbook", templateGroupId: UUID(), libraryId: UUID(),
                                    fields: [NoteTemplateField(name: "Owner", valueType: .text, defaultValue: "")],
                                    bodyTemplate: "# Runbook\n\n## Steps\n\n1. ...")
        let data = try JSONEncoder().encode(original)
        let copy = try JSONDecoder().decode(NoteTemplate.self, from: data)

        #expect(copy.bodyTemplate == original.bodyTemplate)
        #expect(copy.fields == original.fields)
    }

    // MARK: - Apply-after-the-fact

    @Test func applyRetroactivelyBackfillsOnlyMissingFields() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "---\nSpecies: \"Human\"\n---\nBackstory.", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        PropertyDAL.syncProperties(for: documentId, content: try #require(document.content), libraryId: libraryId, in: context)

        let group = TemplateDAL.createGroup(name: "Fiction Writing", libraryId: libraryId, in: context)
        let template = TemplateDAL.createTemplate(name: "Character", templateGroupId: try #require(group.templateGroupId), libraryId: libraryId, fields: [
            NoteTemplateField(name: "Species", valueType: .text, defaultValue: "Kethran"),
            NoteTemplateField(name: "Homeworld", valueType: .text, defaultValue: "Kethra Prime")
        ], in: context)

        TemplateDAL.applyRetroactively(template, to: document, in: context)

        let properties = PropertyDAL.fetchProperties(for: documentId, in: context)
        #expect(properties.first { $0.property.name == "Species" }?.value == "Human", "existing value must not be overwritten")
        #expect(properties.first { $0.property.name == "Homeworld" }?.value == "Kethra Prime", "missing field must be backfilled")
        #expect(document.content?.contains("Backstory.") == true, "free-text body must survive")
    }

    // MARK: - Starter content seeding

    @Test func seedStarterContentCreatesTheThreeDocumentedGroups() throws {
        let context = try makeContext()
        let libraryId = UUID()

        TemplateDAL.seedStarterContent(libraryId: libraryId, in: context)

        let groups = TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context)
        #expect(Set(groups.compactMap { $0.name }) == ["Fiction Writing", "Wedding Planning", "Photography Client Work"])
        for group in groups {
            #expect(!TemplateDAL.fetchActiveTemplates(templateGroupId: try #require(group.templateGroupId), in: context).isEmpty)
        }
    }

    @Test func seedStarterContentIsIdempotentAcrossRepeatedCalls() throws {
        let context = try makeContext()
        let libraryId = UUID()

        TemplateDAL.seedStarterContent(libraryId: libraryId, in: context)
        TemplateDAL.seedStarterContent(libraryId: libraryId, in: context)

        #expect(TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context).count == 3)
    }

    @Test func seedStarterContentDoesNotAffectOtherLibraries() throws {
        let context = try makeContext()
        let libraryOne = UUID()
        let libraryTwo = UUID()

        TemplateDAL.seedStarterContent(libraryId: libraryOne, in: context)

        #expect(TemplateDAL.fetchActiveGroups(libraryId: libraryTwo, in: context).isEmpty)
    }

}
