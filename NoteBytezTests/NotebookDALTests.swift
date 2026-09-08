// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NotebookDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct NotebookDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self, DocumentNotebook.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func createAndFetchActiveReturnsOnlyActiveNotebooksForTheLibrary() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let otherLibraryId = UUID()

        _ = NotebookDAL.create(name: "Book Series", libraryId: libraryId, in: context)
        let toDelete = NotebookDAL.create(name: "Old Project", libraryId: libraryId, in: context)
        _ = NotebookDAL.create(name: "Other Library Notebook", libraryId: otherLibraryId, in: context)
        NotebookDAL.softDelete(toDelete, in: context)

        let active = NotebookDAL.fetchActive(libraryId: libraryId, in: context)

        #expect(active.count == 1)
        #expect(active.first?.name == "Book Series")
    }

    @Test func renameUpdatesName() throws {
        let context = try makeContext()
        let notebook = NotebookDAL.create(name: "Draft Title", libraryId: UUID(), in: context)

        NotebookDAL.rename(notebook, to: "Final Title", in: context)

        #expect(notebook.name == "Final Title")
    }

    @Test func attachIsIdempotentAndDetachSoftDeletesTheJoin() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "content", libraryId: libraryId, in: context)
        let notebook = NotebookDAL.create(name: "Notebook", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let notebookId = try #require(notebook.notebookId)

        NotebookDAL.attach(documentId: documentId, notebookId: notebookId, libraryId: libraryId, in: context)
        NotebookDAL.attach(documentId: documentId, notebookId: notebookId, libraryId: libraryId, in: context)
        #expect(NotebookDAL.fetchNotebooks(for: documentId, in: context).count == 1)

        NotebookDAL.detach(documentId: documentId, notebookId: notebookId, in: context)
        #expect(NotebookDAL.fetchNotebooks(for: documentId, in: context).isEmpty)

        NotebookDAL.attach(documentId: documentId, notebookId: notebookId, libraryId: libraryId, in: context)
        #expect(NotebookDAL.fetchNotebooks(for: documentId, in: context).count == 1)
    }

    @Test func aDocumentCanBelongToZeroOneOrManyNotebooks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Shared Entity", content: "content", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let notebookOne = NotebookDAL.create(name: "Series One", libraryId: libraryId, in: context)
        let notebookTwo = NotebookDAL.create(name: "Series Two", libraryId: libraryId, in: context)

        #expect(NotebookDAL.fetchNotebooks(for: documentId, in: context).isEmpty)

        NotebookDAL.attach(documentId: documentId, notebookId: try #require(notebookOne.notebookId), libraryId: libraryId, in: context)
        #expect(NotebookDAL.fetchNotebooks(for: documentId, in: context).count == 1)

        NotebookDAL.attach(documentId: documentId, notebookId: try #require(notebookTwo.notebookId), libraryId: libraryId, in: context)
        let notebooks = NotebookDAL.fetchNotebooks(for: documentId, in: context)
        #expect(Set(notebooks.compactMap { $0.name }) == ["Series One", "Series Two"])
    }

    @Test func fetchDocumentsReturnsEveryDocumentAttachedToANotebook() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let notebook = NotebookDAL.create(name: "Notebook", libraryId: libraryId, in: context)
        let notebookId = try #require(notebook.notebookId)
        let noteOne = DocumentDAL.create(title: "One", content: "", libraryId: libraryId, in: context)
        let noteTwo = DocumentDAL.create(title: "Two", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Three", content: "", libraryId: libraryId, in: context)

        NotebookDAL.attach(documentId: try #require(noteOne.documentId), notebookId: notebookId, libraryId: libraryId, in: context)
        NotebookDAL.attach(documentId: try #require(noteTwo.documentId), notebookId: notebookId, libraryId: libraryId, in: context)

        let documents = NotebookDAL.fetchDocuments(for: notebook, in: context)
        #expect(Set(documents.compactMap { $0.documentId }) == Set([noteOne.documentId, noteTwo.documentId].compactMap { $0 }))
    }

    @Test func promotedTitleStripsListAndCheckboxMarkersAndTruncates() {
        #expect(NotebookDAL.promotedTitle(from: "- Idea: revamp the onboarding flow") == "Idea: revamp the onboarding flow")
        #expect(NotebookDAL.promotedTitle(from: "- [ ] Ship the release") == "Ship the release")
        #expect(NotebookDAL.promotedTitle(from: "## Heading text") == "Heading text")
        #expect(NotebookDAL.promotedTitle(from: "") == "Untitled")
        #expect(NotebookDAL.promotedTitle(from: String(repeating: "a", count: 200)).count == 80)
    }

    @Test func promoteCreatesAnAttachedDocumentAndLinksBothDirections() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let sourceDocument = JournalDAL.fetchOrCreate(for: Date(), libraryId: libraryId, in: context)
        DocumentDAL.updateContent(sourceDocument, content: "- Idea: revamp the onboarding flow\n- Another line", in: context)
        let notebook = NotebookDAL.create(name: "Product Ideas", libraryId: libraryId, in: context)
        let sourceDocumentId = try #require(sourceDocument.documentId)
        let block = try #require(BlockDAL.fetchActive(documentId: sourceDocumentId, in: context).first { $0.content?.contains("Idea") == true })

        let promoted = try #require(NotebookDAL.promote(block: block, sourceDocument: sourceDocument, into: notebook, in: context))

        #expect(promoted.title == "Idea: revamp the onboarding flow")
        #expect(NotebookDAL.fetchDocuments(for: notebook, in: context).map { $0.documentId }.contains(promoted.documentId))

        let sourceTitle = try #require(sourceDocument.title)
        #expect(WikilinkParser.extractTitles(from: promoted.content ?? "").contains(sourceTitle))
        #expect(WikilinkParser.extractTitles(from: sourceDocument.content ?? "").contains(promoted.title ?? ""))
        #expect((sourceDocument.content ?? "").contains("Another line"))
    }

    @Test func promoteLeavesUnrelatedBlocksInTheSourceDocumentUntouched() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let sourceDocument = JournalDAL.fetchOrCreate(for: Date(), libraryId: libraryId, in: context)
        // Blank line between the two bullets so MarkdownBlockSplitter (blank-line-delimited)
        // treats them as two separate blocks rather than one two-line chunk.
        DocumentDAL.updateContent(sourceDocument, content: "- First idea\n\n- Second idea", in: context)
        let notebook = NotebookDAL.create(name: "Notebook", libraryId: libraryId, in: context)
        let sourceDocumentId = try #require(sourceDocument.documentId)
        let block = try #require(BlockDAL.fetchActive(documentId: sourceDocumentId, in: context).first { $0.content?.contains("First") == true })

        _ = NotebookDAL.promote(block: block, sourceDocument: sourceDocument, into: notebook, in: context)

        let content = sourceDocument.content ?? ""
        #expect(content.contains("- First idea [[First idea]]"))
        #expect(content.contains("- Second idea") && !content.contains("Second idea ["))
    }

    @Test func promoteRecordsBlockAwareProvenanceOnTheNewDocument() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let sourceDocument = JournalDAL.fetchOrCreate(for: Date(), libraryId: libraryId, in: context)
        DocumentDAL.updateContent(sourceDocument, content: "- Idea: revamp the onboarding flow", in: context)
        let notebook = NotebookDAL.create(name: "Product Ideas", libraryId: libraryId, in: context)
        let sourceDocumentId = try #require(sourceDocument.documentId)
        let block = try #require(BlockDAL.fetchActive(documentId: sourceDocumentId, in: context).first)

        let promoted = try #require(NotebookDAL.promote(block: block, sourceDocument: sourceDocument, into: notebook, in: context))

        #expect(promoted.promotedFromDocumentId == sourceDocumentId)
        #expect(promoted.promotedFromBlockId == block.blockId)
    }

    /// Regression test: the previous implementation located the promoted block in the source
    /// content with `range(of:)`, which matches the *first* occurrence of that text anywhere in
    /// the document — so promoting the second of two identical blocks corrupted the first one
    /// instead. The block-aware splice keys off `block.sortOrder`, so it must hit the block the
    /// user actually picked.
    @Test func promotingADuplicateBlockAppendsTheLinkToTheCorrectOccurrence() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let sourceDocument = JournalDAL.fetchOrCreate(for: Date(), libraryId: libraryId, in: context)
        DocumentDAL.updateContent(sourceDocument, content: "- Follow up\n\n- Follow up", in: context)
        let notebook = NotebookDAL.create(name: "Notebook", libraryId: libraryId, in: context)
        let sourceDocumentId = try #require(sourceDocument.documentId)
        let blocks = BlockDAL.fetchActive(documentId: sourceDocumentId, in: context)
        #expect(blocks.count == 2)
        let secondBlock = try #require(blocks.last)
        #expect(secondBlock.sortOrder == 1)

        let promoted = try #require(NotebookDAL.promote(block: secondBlock, sourceDocument: sourceDocument, into: notebook, in: context))

        let chunks = MarkdownBlockSplitter.split(sourceDocument.content ?? "")
        #expect(chunks.count == 2)
        #expect(chunks[0] == "- Follow up")
        #expect(chunks[1] == "- Follow up [[\(promoted.title ?? "")]]")
    }

    /// If the block is genuinely gone from the source by the time `promote` runs — no chunk left
    /// anywhere to reclaim into (see `BlockDAL`'s sticky-identity reclaim pass) — the splice is
    /// skipped rather than guessing — the new document is still created and still carries the
    /// block-aware provenance link, so nothing is lost, but the source content is left alone
    /// rather than risking a corrupt insertion.
    @Test func promoteSkipsTheSpliceWhenTheBlockNoLongerExistsInTheSource() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let sourceDocument = JournalDAL.fetchOrCreate(for: Date(), libraryId: libraryId, in: context)
        DocumentDAL.updateContent(sourceDocument, content: "- Original idea", in: context)
        let notebook = NotebookDAL.create(name: "Notebook", libraryId: libraryId, in: context)
        let sourceDocumentId = try #require(sourceDocument.documentId)
        let staleBlock = try #require(BlockDAL.fetchActive(documentId: sourceDocumentId, in: context).first)

        DocumentDAL.updateContent(sourceDocument, content: "", in: context)

        let promoted = try #require(NotebookDAL.promote(block: staleBlock, sourceDocument: sourceDocument, into: notebook, in: context))

        #expect(promoted.promotedFromBlockId == staleBlock.blockId)
        #expect(sourceDocument.content == "")
    }

    /// Feature B guard (B4): the reclaim pass can leave a reused block whose `content` was
    /// updated to match its new chunk rather than exact-matched — `appendBackLink`'s
    /// `chunks[sortOrder] == blockContent` equality guard still holds for it (both sides read
    /// from the same post-sync state), so a `promote` call that captured the block just before a
    /// same-position edit now finds and splices it, instead of the pre-Feature-B behavior of
    /// treating any edit as having invalidated the reference.
    @Test func promoteSplicesAReclaimedBlockThatWasLightlyEditedSinceItWasRead() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let sourceDocument = JournalDAL.fetchOrCreate(for: Date(), libraryId: libraryId, in: context)
        DocumentDAL.updateContent(sourceDocument, content: "- Original idea about onboarding", in: context)
        let notebook = NotebookDAL.create(name: "Notebook", libraryId: libraryId, in: context)
        let sourceDocumentId = try #require(sourceDocument.documentId)
        let block = try #require(BlockDAL.fetchActive(documentId: sourceDocumentId, in: context).first)
        let originalBlockId = block.blockId

        DocumentDAL.updateContent(sourceDocument, content: "- Original idea about onboarding flow", in: context)
        #expect(block.blockId == originalBlockId)

        let promoted = try #require(NotebookDAL.promote(block: block, sourceDocument: sourceDocument, into: notebook, in: context))

        #expect(sourceDocument.content?.contains("[[\(promoted.title ?? "")]]") == true)
    }

}
