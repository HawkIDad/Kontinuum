// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentViewModel.swift
//  Kontinuum
//

import Foundation
import SwiftData
import Observation

@Observable
final class DocumentViewModel {

    private(set) var document: Document
    private(set) var blocks: [Block] = []
    private(set) var tags: [Tag] = []
    private(set) var tasks: [TaskItem] = []
    private(set) var properties: [PropertyDAL.ResolvedProperty] = []
    private(set) var attachments: [Attachment] = []
    var title: String
    var content: String

    private let modelContext: ModelContext

    init(document: Document, modelContext: ModelContext) {
        self.document = document
        self.modelContext = modelContext
        self.title = document.title ?? ""
        self.content = document.content ?? ""
        self.loadBlocks()
        self.loadTags()
        self.loadTasks()
        self.loadProperties()
        self.loadAttachments()
    }

    /// Resyncs `title`/`content` from the underlying `Document` after something outside this
    /// view model mutated it directly (e.g. `NotebookDAL.promote` appending a backlink to a
    /// journal entry being promoted from). Without this, the next `save()` would overwrite
    /// that external change with this view model's now-stale local copy.
    func reload() {
        title = document.title ?? ""
        content = document.content ?? ""
        loadBlocks()
        loadTags()
        loadTasks()
        loadProperties()
        loadAttachments()
    }

    func loadBlocks() {
        guard let documentId = document.documentId else { return }
        self.blocks = BlockDAL.fetchActive(documentId: documentId, in: modelContext)
    }

    func loadTags() {
        guard let documentId = document.documentId else { return }
        self.tags = TagDAL.fetchTags(for: documentId, in: modelContext)
    }

    func loadTasks() {
        guard let documentId = document.documentId else { return }
        self.tasks = TaskDAL.fetchActive(documentId: documentId, in: modelContext)
    }

    func loadProperties() {
        guard let documentId = document.documentId else { return }
        self.properties = PropertyDAL.fetchProperties(for: documentId, in: modelContext)
    }

    func loadAttachments() {
        guard let documentId = document.documentId else { return }
        self.attachments = AttachmentDAL.fetchActive(documentId: documentId, in: modelContext)
    }

    func save() {
        DocumentDAL.updateTitle(document, title: title, in: modelContext)
        DocumentDAL.updateContent(document, content: content, in: modelContext)
        if let documentId = document.documentId, let libraryId = document.libraryId {
            TagDAL.syncTags(for: documentId, content: content, libraryId: libraryId, in: modelContext)
            TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: modelContext)
            PropertyDAL.syncProperties(for: documentId, content: content, libraryId: libraryId, in: modelContext)
            AttachmentDAL.syncAttachments(for: documentId, content: content, in: modelContext)
            // Workstream C, Decision 12: reconcile only if a board is actually bound to this
            // document — a plain save never scans every board on every keystroke's worth of
            // saves for documents nobody bound anything to.
            for board in CanvasDAL.fetchBoundBoards(boundTo: documentId, in: modelContext) {
                CanvasDAL.reconcileBoundBoard(board, in: modelContext)
            }
        }
        loadBlocks()
        loadTags()
        loadTasks()
        loadProperties()
        loadAttachments()
    }

    /// Copies `fileURL`'s bytes into the app's iCloud ubiquity container and appends its
    /// `![alt](fileName)` embed line to `content`, then saves immediately — a discrete "attach a
    /// file" action, unlike free typing which is only persisted on `save()` (e.g. `onDisappear`).
    /// Returns `false` (without touching `content`) if iCloud is currently unavailable.
    @discardableResult
    func attach(fileURL: URL, mimeType: String) -> Bool {
        guard let documentId = document.documentId else { return false }
        guard let result = try? AttachmentDAL.attach(fileURL: fileURL, mimeType: mimeType, documentId: documentId, content: content, in: modelContext) else {
            return false
        }
        content = result.content
        save()
        return true
    }

    /// Soft-deletes the row and strips its embed line from `content` — content stays the single
    /// source of truth, the same shape `removePropertyValue` already establishes.
    func removeAttachment(_ attachment: Attachment) {
        guard let fileName = attachment.fileName else { return }
        AttachmentDAL.remove(attachment, in: modelContext)
        content = AttachmentParser.removingEmbed(fileName: fileName, from: content)
        save()
    }

    /// Applies whatever a `PluginBridge` run collected via its write-current-note API —
    /// `((anchor))`/wikilink-style content mutation, same "content is the single source of
    /// truth" shape every other write path here uses. Appends land at the end in call order;
    /// inserts are meant to land "at the cursor," but a plugin script never actually sees editor
    /// state (see `PluginBridge.installBridge`'s `insertAtCursor` note) — this app has no
    /// cursor-position tracking to thread through yet, so every insert falls back to the same
    /// end-of-content position an append would use. A real cursor-aware insert is future work,
    /// not silently pretended to exist.
    @discardableResult
    func applyPluginWrites(appends: [String], inserts: [String]) -> Bool {
        guard !appends.isEmpty || !inserts.isEmpty else { return false }
        for text in appends + inserts {
            content += (content.isEmpty || content.hasSuffix("\n") ? "" : "\n") + text
        }
        save()
        return true
    }

    /// Writes a Property value into `content`'s frontmatter (via `PropertyParser.applying`)
    /// and saves immediately — a discrete form-field commit, unlike free typing which is only
    /// persisted on `save()`. Content stays the single source of truth: this never touches
    /// `PropertyDAL` directly, `save()`'s `syncProperties` pass reconciles the index from the
    /// content this just wrote, the same shape `toggleTask` already established for tasks.
    func setPropertyValue(key: String, value: String, valueType: PropertyValueType) {
        content = PropertyParser.applying(key: key, value: value, valueType: valueType, to: content)
        save()
    }

    func removePropertyValue(key: String) {
        content = PropertyParser.removingProperty(key: key, from: content)
        save()
    }

    /// Apply-after-the-fact: backfills `template`'s fields onto this already-existing document
    /// (only the ones it doesn't already have a value for — see `TemplateDAL.applyRetroactively`),
    /// then resyncs from the `Document` the DAL call just mutated directly.
    func applyTemplateRetroactively(_ template: NoteTemplate) {
        TemplateDAL.applyRetroactively(template, to: document, in: modelContext)
        reload()
    }

    /// Which `TemplateDAL.PickerScope` this document's own "Apply Template" action should use:
    /// its first Notebook if it belongs to one, the Journal if it's a journal entry, otherwise
    /// every template in the library.
    func templatePickerScope() -> TemplateDAL.PickerScope {
        if let documentId = document.documentId,
           let firstNotebookId = NotebookDAL.fetchNotebooks(for: documentId, in: modelContext).first?.notebookId {
            return .notebook(firstNotebookId)
        }
        if document.isJournalEntry == true {
            return .journal
        }
        return .library
    }

    /// Flips the Nth checkbox line's state and saves immediately — a discrete tap action,
    /// unlike free typing which is only persisted on `save()` (e.g. `onDisappear`).
    func toggleTask(at index: Int) {
        content = TaskParser.toggling(taskIndex: index, in: content)
        save()
    }

    var activeWikilinkQuery: String? {
        WikilinkParser.activeQuery(in: content)
    }

    func wikilinkSuggestions(matching query: String, limit: Int = 8) -> [String] {
        guard let libraryId = document.libraryId else { return [] }
        let currentDocumentId = document.documentId

        let titles = DocumentDAL.fetchActive(libraryId: libraryId, in: modelContext)
            .filter { $0.documentId != currentDocumentId }
            .compactMap { $0.title }
            .filter { !$0.isEmpty }

        return Array(titles.filter { WikilinkParser.fuzzyMatches($0, query: query) }.prefix(limit))
    }

    func insertWikilink(title: String) {
        content = WikilinkParser.applying(title: title, to: content)
    }

    func resolveWikilink(title: String) -> Document? {
        guard let libraryId = document.libraryId else { return nil }
        return DocumentDAL.fetchActive(libraryId: libraryId, in: modelContext)
            .first { $0.title?.caseInsensitiveCompare(title) == .orderedSame }
    }

    /// Resolves a `[[Title#Heading]]` section link: the document via the same lookup
    /// `resolveWikilink` uses, then among its active blocks the one whose own heading-line slug
    /// — or, failing that, the last segment of its `headingPath` — matches `heading`'s slug. A
    /// `nil` block means the heading wasn't found; the document itself still resolves, so the
    /// caller can navigate there and open at the top rather than treating the whole link as dead.
    func resolveSectionLink(title: String, heading: String) -> (document: Document, block: Block?)? {
        guard let target = resolveWikilink(title: title) else { return nil }
        guard let documentId = target.documentId else { return (document: target, block: nil) }

        let targetSlug = BlockDAL.slugify(heading)
        let block = BlockDAL.fetchActive(documentId: documentId, in: modelContext).first { block in
            if let ownSlug = Self.headingLineSlug(of: block.content) {
                return ownSlug == targetSlug
            }
            if let lastSegment = block.headingPath?.components(separatedBy: " > ").last {
                return BlockDAL.slugify(lastSegment) == targetSlug
            }
            return false
        }
        return (document: target, block: block)
    }

    /// Every ATX heading title in the document titled `title`, fuzzy-filtered by `query` — the
    /// suggestion source for the `#` segment of an in-progress `[[Title#query` section link.
    func headingSuggestions(forDocumentTitled title: String, matching query: String, limit: Int = 8) -> [String] {
        guard let content = resolveWikilink(title: title)?.content else { return [] }
        let headings = MarkdownBlockSplitter.split(withHeadingContext: content)
            .map(\.content)
            .compactMap(Self.headingTitle(of:))
        return Array(headings.filter { WikilinkParser.fuzzyMatches($0, query: query) }.prefix(limit))
    }

    /// The raw title text of an ATX heading line (hashes and surrounding whitespace stripped),
    /// or `nil` if `content` isn't a heading line at all.
    private static func headingTitle(of content: String) -> String? {
        guard content.hasPrefix("#") else { return nil }
        let stripped = content.drop(while: { $0 == "#" })
        guard stripped.isEmpty || stripped.first == " " || stripped.first == "\t" else { return nil }
        let title = stripped.trimmingCharacters(in: .whitespaces)
        return title.isEmpty ? nil : title
    }

    private static func headingLineSlug(of content: String?) -> String? {
        guard let content, let title = headingTitle(of: content) else { return nil }
        return BlockDAL.slugify(title)
    }

    var activeTagQuery: String? {
        TagParser.activeQuery(in: content)
    }

    func tagSuggestions(matching query: String, limit: Int = 8) -> [String] {
        guard let libraryId = document.libraryId else { return [] }
        let names = TagDAL.fetchActive(libraryId: libraryId, in: modelContext).compactMap { $0.name }
        return Array(names.filter { WikilinkParser.fuzzyMatches($0, query: query) }.prefix(limit))
    }

    func insertTag(name: String) {
        content = TagParser.applying(tag: name, to: content)
    }

    var activeBlockReferenceQuery: String? {
        BlockReferenceParser.activeQuery(in: content)
    }

    /// The in-progress `!((query` — checked separately from `activeBlockReferenceQuery` (which
    /// would also match it, since `activeQuery` doesn't care what precedes `((`) so the editing
    /// strip can offer the same suggestion list but insert the `!`-prefixed embed form instead.
    var activeEmbedReferenceQuery: String? {
        BlockReferenceParser.activeEmbedQuery(in: content)
    }

    func blockReferenceSuggestions(matching query: String, limit: Int = 8) -> [Block] {
        guard let libraryId = document.libraryId else { return [] }
        return BlockReferenceDAL.autocompleteMatches(query: query, libraryId: libraryId, in: modelContext, limit: limit)
    }

    func insertBlockReference(anchor: String) {
        content = BlockReferenceParser.applying(anchor: anchor, to: content)
    }

    func insertEmbedReference(anchor: String) {
        content = BlockReferenceParser.applying(embedAnchor: anchor, to: content)
    }

    /// Resolves a tapped `((anchor))` reference to the `Block` (and its owning `Document`) it
    /// points to, preferring a match within this document over the library-wide fallback — see
    /// `BlockReferenceDAL.resolve`.
    func resolveBlockReference(anchor: String) -> BlockReferenceDAL.ResolvedBlockReference? {
        guard let libraryId = document.libraryId else { return nil }
        return BlockReferenceDAL.resolve(anchor: anchor, preferringDocumentId: document.documentId, libraryId: libraryId, in: modelContext)
    }

    /// Resolves `anchor` to its current `Block`/`Document` for live transclusion (Decision 5) —
    /// re-resolved fresh on every call, same "resolve at render time" pattern
    /// `embeddedSearchResults` already uses, so editing the source and re-querying sees the new
    /// text. `visitedAnchors` is the depth-1 cycle guard: an anchor already in the set (this
    /// embed is itself being rendered inside an expansion that already expanded it) resolves to
    /// `nil` instead of recursing — the render path renders that case as a plain link instead.
    func transclusion(for anchor: String, visitedAnchors: Set<String> = []) -> BlockReferenceDAL.ResolvedBlockReference? {
        guard !visitedAnchors.contains(anchor) else { return nil }
        return resolveBlockReference(anchor: anchor)
    }

    /// Live results for an embedded ` ```query ``` ` block (see `EmbeddedSearchBlockParser`) —
    /// resolved fresh every time the preview renders, never cached on the `Document`.
    func embeddedSearchResults(for query: String) -> [SearchDAL.SearchResult] {
        guard let libraryId = document.libraryId else { return [] }
        return SearchDAL.searchAdvanced(query: query, scope: .content, libraryId: libraryId, in: modelContext)
    }

    /// The already-loaded `Block` containing `lineText` as one of its own lines — a journal
    /// thought is usually its own block (exact whole-block match); a multi-line block matches
    /// via containment. Used to find which `Block` a rendered preview row belongs to, for the
    /// Promote-to-Notebook context menu (Decision 3) — the block is the promotable unit, not
    /// the individual rendered line.
    func block(containingLine lineText: String) -> Block? {
        let trimmed = lineText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return blocks.first { block in
            (block.content ?? "").components(separatedBy: "\n").contains { $0.trimmingCharacters(in: .whitespaces) == trimmed }
        }
    }

    /// Commits an edit made in place inside a `!((anchor))` transclusion (Workstream B,
    /// Decision 6(a): optimistic write, last-write-wins — no staleness check, no diff-merge
    /// prompt). Splices `newText` into the *source* document's content at the target block's
    /// current position, the same `TaskDAL.toggle`/`NotebookDAL.appendBackLink` splice-through-
    /// `DocumentDAL.updateContent` shape every other cross-block write in this app uses — never
    /// mutates `Block.content` directly, since that's a derived cache of the document's content,
    /// not an independent source of truth. `BlockDAL.syncBlocks`' own sticky-identity reclaim
    /// pass (same index + heading path) then keeps the block's `blockId`/`anchor` stable across
    /// the edit, so this needs no bookkeeping of its own to preserve identity.
    @discardableResult
    func commitTransclusionEdit(anchor: String, newText: String) -> Bool {
        guard let resolved = resolveBlockReference(anchor: anchor),
              let sourceContent = resolved.document.content,
              let sortOrder = resolved.block.sortOrder
        else { return false }

        var chunks = MarkdownBlockSplitter.split(sourceContent)
        guard chunks.indices.contains(sortOrder) else { return false }

        chunks[sortOrder] = newText
        let updatedContent = MarkdownBlockSplitter.join(chunks)
        DocumentDAL.updateContent(resolved.document, content: updatedContent, in: modelContext)

        // Full reconciliation of the *source* document (B5) — an in-place edit can add/remove a
        // task, tag, property, or attachment reference just as easily as a normal edit can, so
        // this mirrors every `syncX` call `save()` makes for the document actually being typed
        // into, not just the block-level `syncBlocks` `updateContent` already triggers.
        if let sourceDocumentId = resolved.document.documentId, let sourceLibraryId = resolved.document.libraryId {
            TagDAL.syncTags(for: sourceDocumentId, content: updatedContent, libraryId: sourceLibraryId, in: modelContext)
            TaskDAL.syncTasks(for: sourceDocumentId, libraryId: sourceLibraryId, in: modelContext)
            PropertyDAL.syncProperties(for: sourceDocumentId, content: updatedContent, libraryId: sourceLibraryId, in: modelContext)
            AttachmentDAL.syncAttachments(for: sourceDocumentId, content: updatedContent, in: modelContext)
        }

        return true
    }

    /// Thin wrapper over `NotebookDAL.promote`, locating the block by `sortOrder` among the
    /// already-loaded `blocks` — the same identity `TaskDAL.toggle` keys its own splice by.
    /// `NotebookDAL.promote`'s own `appendBackLink` re-verifies the block still matches at that
    /// position before splicing, so this only needs to find the right `Block`, not re-check
    /// staleness itself. Restores the direct context-menu gesture (Decision 3) alongside the
    /// existing `PromoteBlockPickerView` toolbar path — both end at this one call.
    @discardableResult
    func promoteBlock(at sortOrder: Int, into notebook: Notebook) -> Document? {
        guard let block = blocks.first(where: { $0.sortOrder == sortOrder }) else { return nil }
        let promoted = NotebookDAL.promote(block: block, sourceDocument: document, into: notebook, in: modelContext)
        reload()
        return promoted
    }

}
