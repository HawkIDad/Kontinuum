// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentViewModelTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

/// `toggleTask` already has coverage via `TaskDALTests`; this fills in the rest of
/// `DocumentViewModel`'s pure logic — save propagation, wikilink/tag autocomplete, and the
/// `reload()` resync path Phase 8's Promote-to-Notebook flow depends on.
struct DocumentViewModelTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, TaskItem.self, Property.self, DocumentProperty.self, Notebook.self, DocumentNotebook.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func saveWritesTitleAndContentAndReindexesTagsAndTasks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Original", content: "Nothing yet", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)

        viewModel.title = "Renamed"
        viewModel.content = "Ping #idea\n- [ ] follow up"
        viewModel.save()

        #expect(document.title == "Renamed")
        #expect(document.content == "Ping #idea\n- [ ] follow up")
        #expect(viewModel.tags.map { $0.name } == ["idea"])
        #expect(viewModel.tasks.count == 1)
    }

    @Test func setPropertyValueWritesFrontmatterAndReindexesProperties() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "Backstory.", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)

        viewModel.setPropertyValue(key: "Species", value: "Kethran", valueType: .text)

        #expect(viewModel.content.contains("Species: \"Kethran\""))
        #expect(viewModel.content.contains("Backstory."))
        #expect(viewModel.properties.count == 1)
        #expect(viewModel.properties.first?.value == "Kethran")
    }

    @Test func removePropertyValueDropsTheFrontmatterLineAndTheIndexedValue() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Elyra Voss", content: "Backstory.", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)
        viewModel.setPropertyValue(key: "Species", value: "Kethran", valueType: .text)

        viewModel.removePropertyValue(key: "Species")

        #expect(!viewModel.content.contains("Species"))
        #expect(viewModel.properties.isEmpty)
    }

    @Test func reloadResyncsFromAnExternallyMutatedDocument() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Journal", content: "Original line", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)

        // Simulate NotebookDAL.promote appending directly to the underlying Document.
        DocumentDAL.updateContent(document, content: "Original line\n[[Promoted Note]]", in: context)

        viewModel.reload()

        #expect(viewModel.content == "Original line\n[[Promoted Note]]")
    }

    @Test func wikilinkSuggestionsExcludeTheCurrentDocumentAndUntitledNotes() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let current = DocumentDAL.create(title: "Today", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Roadmap", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "", content: "", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: current, modelContext: context)
        let suggestions = viewModel.wikilinkSuggestions(matching: "road")

        #expect(suggestions == ["Roadmap"])
    }

    @Test func insertWikilinkAppliesToContent() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Today", content: "See [[road", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)
        viewModel.content = "See [[road"

        viewModel.insertWikilink(title: "Roadmap")

        #expect(viewModel.content == "See [[Roadmap]] ")
    }

    @Test func resolveWikilinkFindsATitleCaseInsensitively() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let current = DocumentDAL.create(title: "Today", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Roadmap", content: "", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: current, modelContext: context)
        let resolved = viewModel.resolveWikilink(title: "roadmap")

        #expect(resolved?.title == "Roadmap")
    }

    @Test func resolveWikilinkReturnsNilWhenNoTitleMatches() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let current = DocumentDAL.create(title: "Today", content: "", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: current, modelContext: context)
        #expect(viewModel.resolveWikilink(title: "Nonexistent") == nil)
    }

    // MARK: - promoteBlock(at:into:) (Restore Direct Promote-to-Notebook Gesture)

    @Test func promoteBlockCreatesADocumentInTheNotebookAndLinksBothDirectionsLeavingTheBlockTextIntact() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Journal", content: "- Idea: ship the palette", libraryId: libraryId, in: context)
        let notebook = NotebookDAL.create(name: "Ideas", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)
        let sortOrder = try #require(viewModel.blocks.first?.sortOrder)

        let promoted = try #require(viewModel.promoteBlock(at: sortOrder, into: notebook))

        #expect(promoted.title == "Idea: ship the palette")
        #expect(NotebookDAL.fetchDocuments(for: notebook, in: context).map { $0.documentId }.contains(promoted.documentId))
        #expect(viewModel.content.hasPrefix("- Idea: ship the palette"))
        #expect(WikilinkParser.extractTitles(from: viewModel.content).contains(promoted.title ?? ""))
        #expect(WikilinkParser.extractTitles(from: promoted.content ?? "").contains(document.title ?? ""))
    }

    @Test func promoteBlockReturnsNilForASortOrderThatDoesNotMatchAnyLoadedBlock() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Journal", content: "- Only block", libraryId: libraryId, in: context)
        let notebook = NotebookDAL.create(name: "Ideas", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)

        #expect(viewModel.promoteBlock(at: 999, into: notebook) == nil)
    }

    // MARK: - transclusion(for:) (Live Block Transclusion — Decision 5)

    @Test func transclusionReturnsTheCurrentContentOfTheTargetBlock() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target", content: "# Review PR\n\nOriginal text.", libraryId: libraryId, in: context)
        let targetId = try #require(target.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: targetId, in: context).first { $0.content == "Original text." }?.anchor)
        // Surrounding text, not just the bare embed — a lone `!((anchor))` line's own
        // auto-generated anchor would otherwise slugify right back to `anchor` itself (the
        // punctuation strips away to nothing else), colliding with the very block it embeds.
        let current = DocumentDAL.create(title: "Journal", content: "Embed below:\n\n!((\(anchor))) noted.", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: current, modelContext: context)

        let resolved = try #require(viewModel.transclusion(for: anchor))
        #expect(resolved.block.content == "Original text.")

        DocumentDAL.updateContent(target, content: "# Review PR\n\nUpdated text.", in: context)

        let reResolved = try #require(viewModel.transclusion(for: anchor))
        #expect(reResolved.block.content == "Updated text.")
    }

    @Test func transclusionReturnsNilForAnUnresolvableAnchor() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Journal", content: "Reference: !((does-not-exist)) noted.", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)

        #expect(viewModel.transclusion(for: "does-not-exist") == nil)
    }

    @Test func transclusionReturnsNilWhenTheAnchorIsAlreadyInTheVisitedSetDepthCap() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target", content: "# Review PR\n\nSome text.", libraryId: libraryId, in: context)
        let targetId = try #require(target.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: targetId, in: context).first { $0.content == "Some text." }?.anchor)
        let document = DocumentDAL.create(title: "Journal", content: "!((\(anchor)))", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)

        #expect(viewModel.transclusion(for: anchor, visitedAnchors: [anchor]) == nil)
    }

    // MARK: - resolveSectionLink / headingSuggestions (Feature C — [[Title#Heading]])

    @Test func resolveSectionLinkFindsTheHeadingBlockBySlug() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let current = DocumentDAL.create(title: "Today", content: "", libraryId: libraryId, in: context)
        let target = DocumentDAL.create(title: "Note", content: "# Intro\n\n## Setup\n\nDo this first.", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: current, modelContext: context)
        let resolved = viewModel.resolveSectionLink(title: "Note", heading: "Setup")

        #expect(resolved?.document.documentId == target.documentId)
        #expect(resolved?.block?.content == "## Setup")
    }

    @Test func resolveSectionLinkReturnsNilBlockButStillResolvesTheDocumentWhenHeadingIsNotFound() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let current = DocumentDAL.create(title: "Today", content: "", libraryId: libraryId, in: context)
        let target = DocumentDAL.create(title: "Note", content: "# Intro\n\nSome text.", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: current, modelContext: context)
        let resolved = viewModel.resolveSectionLink(title: "Note", heading: "Nonexistent")

        #expect(resolved?.document.documentId == target.documentId)
        #expect(resolved?.block == nil)
    }

    @Test func resolveSectionLinkReturnsNilWhenTheDocumentItselfIsNotFound() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let current = DocumentDAL.create(title: "Today", content: "", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: current, modelContext: context)
        #expect(viewModel.resolveSectionLink(title: "Missing", heading: "Setup") == nil)
    }

    @Test func headingSuggestionsFuzzyMatchesHeadingsInTheNamedDocument() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let current = DocumentDAL.create(title: "Today", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Note", content: "# Intro\n\n## Setup Guide\n\nDo this.", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: current, modelContext: context)
        let suggestions = viewModel.headingSuggestions(forDocumentTitled: "Note", matching: "setup")

        #expect(suggestions == ["Setup Guide"])
    }

    @Test func tagSuggestionsMatchExistingLibraryTags() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Today", content: "#idea", libraryId: libraryId, in: context)
        _ = TagDAL.syncTags(for: try #require(document.documentId), content: "#idea", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: document, modelContext: context)
        let suggestions = viewModel.tagSuggestions(matching: "id")

        #expect(suggestions == ["idea"])
    }

    @Test func activeWikilinkQueryReflectsAnUnclosedBracketPair() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Today", content: "", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)

        viewModel.content = "See [[road"
        #expect(viewModel.activeWikilinkQuery == "road")

        viewModel.content = "See [[Roadmap]]"
        #expect(viewModel.activeWikilinkQuery == nil)
    }

    @Test func activeTagQueryReflectsAnInProgressHashtag() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Today", content: "", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)

        viewModel.content = "Ping #id"
        #expect(viewModel.activeTagQuery == "id")

        viewModel.content = "Ping #idea done"
        #expect(viewModel.activeTagQuery == nil)
    }

    @Test func insertTagAppliesToContent() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Today", content: "Ping #id", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: document, modelContext: context)
        viewModel.content = "Ping #id"

        viewModel.insertTag(name: "idea")

        #expect(viewModel.content == "Ping #idea ")
    }

}
