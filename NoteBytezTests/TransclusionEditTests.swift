// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TransclusionEditTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

/// Workstream B (`NoteBytez20260829v2-Enhancements.md`) — editable-in-place transclusion.
/// Decision 6(a): optimistic write, last-write-wins within the device. No diff-merge prompt —
/// a commit always applies directly to the source document's content (spliced by the target
/// block's current position, same pattern `TaskDAL.toggle`/`NotebookDAL.appendBackLink` use),
/// letting `BlockDAL.syncBlocks`' existing sticky-identity reclaim pass keep the block's
/// `blockId`/`anchor` stable across the edit.
struct TransclusionEditTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, TaskItem.self, Property.self, DocumentProperty.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func commitWritesTheNewTextToTheSourceBlockAndBothNotesSeeIt() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Meeting Notes", content: "# Action Items\n\nFollow up with Dana.", libraryId: libraryId, in: context)
        let sourceId = try #require(source.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.content == "Follow up with Dana." }?.anchor)
        let originalBlockId = BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.anchor == anchor }?.blockId

        let embedding = DocumentDAL.create(title: "Journal", content: "Recap:\n\n!((\(anchor))) noted.", libraryId: libraryId, in: context)
        let embeddingViewModel = DocumentViewModel(document: embedding, modelContext: context)

        let committed = embeddingViewModel.commitTransclusionEdit(anchor: anchor, newText: "Follow up with Dana about the budget.")

        #expect(committed)
        #expect(source.content == "# Action Items\n\nFollow up with Dana about the budget.")
        let updatedBlock = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.anchor == anchor })
        #expect(updatedBlock.content == "Follow up with Dana about the budget.")
        // Sticky identity (Anchors plan) keeps the same blockId across the edit.
        #expect(updatedBlock.blockId == originalBlockId)

        // Re-rendering the embed sees the new text immediately (resolve at render time).
        let reResolved = try #require(embeddingViewModel.transclusion(for: anchor))
        #expect(reResolved.block.content == "Follow up with Dana about the budget.")
    }

    @Test func commitReturnsFalseForAnUnresolvableAnchor() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let embedding = DocumentDAL.create(title: "Journal", content: "Reference: !((does-not-exist)) noted.", libraryId: libraryId, in: context)
        let viewModel = DocumentViewModel(document: embedding, modelContext: context)

        #expect(!viewModel.commitTransclusionEdit(anchor: "does-not-exist", newText: "Anything"))
    }

    @Test func commitIsOptimisticAndAppliesEvenIfTheSourceChangedSinceTheEmbedWasRendered() throws {
        // Decision 6(a): no guard, no diff-merge prompt — last write always wins.
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Meeting Notes", content: "# Action Items\n\nFollow up with Dana.", libraryId: libraryId, in: context)
        let sourceId = try #require(source.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.content == "Follow up with Dana." }?.anchor)

        let embedding = DocumentDAL.create(title: "Journal", content: "Recap:\n\n!((\(anchor))) noted.", libraryId: libraryId, in: context)
        let embeddingViewModel = DocumentViewModel(document: embedding, modelContext: context)

        // The source changes elsewhere (a different editor session) after the embed rendered.
        DocumentDAL.updateContent(source, content: "# Action Items\n\nFollow up with Dana urgently.", in: context)

        let committed = embeddingViewModel.commitTransclusionEdit(anchor: anchor, newText: "Follow up with Dana about the budget.")

        #expect(committed)
        #expect(source.content == "# Action Items\n\nFollow up with Dana about the budget.")
    }

    @Test func aNestedEmbedInsideTheEditedTextIsNotExpandedItStaysLiteral() throws {
        // Depth-1 invariant (Decision 8): the editable region is plain text; a `!((x))` typed
        // into it is not turned into a nested editor — it's just characters until the next
        // render pass treats it as a plain link inside the (non-recursive) transcluded view.
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Notes", content: "# Section\n\nOriginal text.", libraryId: libraryId, in: context)
        let sourceId = try #require(source.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.content == "Original text." }?.anchor)
        let embedding = DocumentDAL.create(title: "Journal", content: "Recap:\n\n!((\(anchor))) noted.", libraryId: libraryId, in: context)
        let embeddingViewModel = DocumentViewModel(document: embedding, modelContext: context)

        _ = embeddingViewModel.commitTransclusionEdit(anchor: anchor, newText: "See !((some-other-anchor)) too.")

        let updatedBlock = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.anchor == anchor })
        #expect(updatedBlock.content == "See !((some-other-anchor)) too.")
        // No new Block was recursively created/expanded for the nested embed text — it's just
        // literal text inside this one block's content.
        #expect(BlockDAL.fetchActive(documentId: sourceId, in: context).count == 2)
    }

    // MARK: - Task-index integrity (B5)

    @Test func editingATranscludedBlockIntoATaskKeepsTheSourceDocumentsTaskIndexInSync() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Project", content: "# Notes\n\nSomething to do.", libraryId: libraryId, in: context)
        let sourceId = try #require(source.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.content == "Something to do." }?.anchor)
        let embedding = DocumentDAL.create(title: "Journal", content: "Recap:\n\n!((\(anchor))) noted.", libraryId: libraryId, in: context)
        let embeddingViewModel = DocumentViewModel(document: embedding, modelContext: context)

        _ = embeddingViewModel.commitTransclusionEdit(anchor: anchor, newText: "- [ ] Something to do.")

        let sourceTasks = TaskDAL.fetchActive(documentId: sourceId, in: context)
        #expect(sourceTasks.count == 1)
        #expect(sourceTasks.first?.isDone == false)

        // Toggling it (e.g. from the Task Dashboard, or the source note's own preview) works
        // correctly from this point on — the edit didn't leave the index stale.
        let toggled = TaskDAL.toggle(try #require(sourceTasks.first), in: context)
        #expect(toggled)
        #expect(TaskDAL.fetchActive(documentId: sourceId, in: context).first?.isDone == true)
    }

    // MARK: - Export round-trip (B6)

    @Test func editingTheSourceLeavesTheEmbeddingNotesLiteralSigilUntouched() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let source = DocumentDAL.create(title: "Meeting Notes", content: "# Action Items\n\nFollow up with Dana.", libraryId: libraryId, in: context)
        let sourceId = try #require(source.documentId)
        let anchor = try #require(BlockDAL.fetchActive(documentId: sourceId, in: context).first { $0.content == "Follow up with Dana." }?.anchor)
        let embeddingContent = "Recap:\n\n!((\(anchor))) noted."
        let embedding = DocumentDAL.create(title: "Journal", content: embeddingContent, libraryId: libraryId, in: context)
        let embeddingViewModel = DocumentViewModel(document: embedding, modelContext: context)

        _ = embeddingViewModel.commitTransclusionEdit(anchor: anchor, newText: "Follow up with Dana about the budget.")

        // The embedding note's own raw content — what actually exports to disk — never
        // contained the target's text in the first place, only the sigil, so it's untouched.
        #expect(embedding.content == embeddingContent)
        #expect(ExportDAL.exportableContent(for: embedding, in: context).contains("!((\(anchor)))"))
        #expect(ExportDAL.exportableContent(for: source, in: context).contains("Follow up with Dana about the budget."))
    }

}
