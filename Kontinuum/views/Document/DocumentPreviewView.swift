// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DocumentPreviewView.swift
//  Kontinuum
//

import SwiftUI
import MarkdownG9

/// Shared preview renderer for S3 (Today/Journal) and S4 (Document View) — using the same
/// component for both is what guarantees a task's toggle state is identical regardless of
/// which screen it was toggled from, rather than two implementations that could drift.
///
/// `Text(AttributedString)` can't host a real, reliably-tappable button inline, so a document
/// with no checkbox lines and no embedded query block (see `EmbeddedSearchBlockParser`)
/// renders exactly as before: one `MDProcessor.process(_:)` pass over the whole content,
/// preserving multi-line constructs (fenced code blocks, wrapped paragraphs) that only make
/// sense read as a unit. A document that has either switches to a line-by-line render so a
/// task line can pair a real `TaskCheckbox` button with its text, and a query block can
/// resolve to a live `EmbeddedSearchResultsView` — the tradeoff being that multi-line
/// constructs are then read one line at a time. Acceptable for MVP: per Journey 2,
/// journal/task content is short bullet lines, not long wrapped prose or embedded code blocks.
struct DocumentPreviewView: View {

    let documentViewModel: DocumentViewModel

    /// A `[[Note#Heading]]` section link's target block content, best-effort scrolled to when
    /// this preview is on the line-by-line path (see `LineBasedPreview`) — the whole-document
    /// `Text(MDProcessor.process(...))` path below has no addressable per-line anchors, so it
    /// simply opens at the top, same as before this existed (Decision 7).
    var scrollTargetLineText: String? = nil

    private var needsLineByLineRendering: Bool {
        !TaskParser.extractTasks(from: documentViewModel.content).isEmpty
            || EmbeddedSearchBlockParser.containsQueryBlock(documentViewModel.content)
            || AttachmentParser.containsAttachmentEmbed(documentViewModel.content)
            || BlockReferenceParser.containsEmbed(documentViewModel.content)
    }

    var body: some View {
        ScrollView {
            Group {
                if needsLineByLineRendering {
                    LineBasedPreview(documentViewModel: documentViewModel, scrollTargetLineText: scrollTargetLineText)
                } else {
                    Text(MDProcessor.process(documentViewModel.content))
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }

}

/// Renders task checkboxes and embedded query blocks as real interactive views; everything
/// else still goes through `MDProcessor`, one line at a time.
private struct LineBasedPreview: View {

    let documentViewModel: DocumentViewModel
    var scrollTargetLineText: String? = nil

    @Environment(\.modelContext) private var modelContext
    @State private var previewedAttachment: Attachment?
    @State private var promoteTarget: Block?
    @State private var transclusionSourceTarget: Document?

    private struct RenderableLine: Identifiable {
        let id: Int
        let text: String
        let task: TaskParser.TaskMatch?
        let taskIndex: Int?
        let embeddedQuery: String?
        let attachment: Attachment?
        let embedAnchor: String?
    }

    /// Task indices must stay correct against the *whole* document (`toggleTask(at:)` indexes
    /// every checkbox line in document order), so this walks `EmbeddedSearchBlockParser`'s
    /// output — which already preserves line order — rather than re-deriving line numbers from
    /// a segmented view of the content.
    private var renderableLines: [RenderableLine] {
        var result: [RenderableLine] = []
        var taskCounter = 0
        var lineId = 0

        for contentLine in EmbeddedSearchBlockParser.parse(documentViewModel.content) {
            switch contentLine {
            case .plain(let text):
                let task = TaskParser.match(in: text)
                let taskIndex = task != nil ? taskCounter : nil
                if task != nil { taskCounter += 1 }
                let attachment = AttachmentParser.match(in: text).flatMap { match in
                    documentViewModel.attachments.first { $0.fileName == match.fileName }
                }
                let embedAnchor = BlockReferenceParser.extractEmbeds(from: text).first
                result.append(RenderableLine(id: lineId, text: text, task: task, taskIndex: taskIndex, embeddedQuery: nil, attachment: attachment, embedAnchor: embedAnchor))
            case .query(let query):
                result.append(RenderableLine(id: lineId, text: "", task: nil, taskIndex: nil, embeddedQuery: query, attachment: nil, embedAnchor: nil))
            }
            lineId += 1
        }
        return result
    }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(alignment: .leading, spacing: 4) {
                ForEach(renderableLines) { line in
                    if let query = line.embeddedQuery {
                        EmbeddedSearchResultsView(query: query, documentViewModel: documentViewModel)
                    } else if let embedAnchor = line.embedAnchor {
                        TransclusionBlockView(anchor: embedAnchor, documentViewModel: documentViewModel) { source in
                            transclusionSourceTarget = source
                        }
                    } else if let attachment = line.attachment {
                        AttachmentThumbnail(attachment: attachment) { previewedAttachment = attachment }
                    } else if let task = line.task, let taskIndex = line.taskIndex {
                        HStack(alignment: .center, spacing: 8) {
                            TaskCheckbox(label: task.text, isDone: task.isDone) {
                                documentViewModel.toggleTask(at: taskIndex)
                            }
                            Text(MDProcessor.process(task.text))
                                .textSelection(.enabled)
                                .strikethrough(task.isDone)
                                .foregroundStyle(task.isDone ? .secondary : .primary)
                        }
                        .contextMenu { promoteMenuItems(for: line.text) }
                    } else if !line.text.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text(MDProcessor.process(line.text))
                            .textSelection(.enabled)
                            .contextMenu { promoteMenuItems(for: line.text) }
                    } else {
                        Color.clear.frame(height: 8)
                    }
                }
            }
            .onAppear {
                guard let target = scrollTargetLineText?.trimmingCharacters(in: .whitespacesAndNewlines),
                      let matchId = renderableLines.first(where: { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) == target })?.id
                else { return }
                proxy.scrollTo(matchId, anchor: .top)
            }
        }
        .sheet(item: $previewedAttachment) { attachment in
            AttachmentPreview(attachment: attachment)
        }
        .sheet(item: $promoteTarget) { block in
            if let libraryId = documentViewModel.document.libraryId {
                PromoteToNotebookView(
                    viewModel: NotebookViewModel(libraryId: libraryId, modelContext: modelContext),
                    block: block,
                    sourceDocument: documentViewModel.document,
                    onPromoted: { _ in
                        documentViewModel.reload()
                        promoteTarget = nil
                    }
                )
            }
        }
        .navigationDestination(item: $transclusionSourceTarget) { document in
            DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
        }
    }

    /// Restores the direct context-menu Promote gesture (Decision 3) — long-press on iOS,
    /// right-click on macOS — alongside the existing toolbar `PromoteBlockPickerView` fallback.
    /// Journal entries only: promoting from a non-journal document isn't a supported operation.
    @ViewBuilder
    private func promoteMenuItems(for lineText: String) -> some View {
        if documentViewModel.document.isJournalEntry == true, let block = documentViewModel.block(containingLine: lineText) {
            Button {
                promoteTarget = block
            } label: {
                Label("Promote to Notebook", systemImage: "books.vertical")
            }
        }
    }

}

/// Live results for one embedded ` ```query ``` ` block — resolved fresh on every render, per
/// NoteBytez-ReleaseFeatures.md's "resolves at render/preview time, not persisted as static
/// content." Display-only for this first cut: rows aren't tappable-to-navigate, since
/// `DocumentPreviewView` is shared between S3/S4 and neither currently threads a navigation
/// callback through it — a real but scoped-out gap, not an oversight.
private struct EmbeddedSearchResultsView: View {

    let query: String
    let documentViewModel: DocumentViewModel

    var body: some View {
        let results = documentViewModel.embeddedSearchResults(for: query)

        VStack(alignment: .leading, spacing: 4) {
            Text(query)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)

            if results.isEmpty {
                Text("No matches.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(results) { result in
                    Text(result.document.title ?? "Untitled")
                        .font(.callout)
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.noteBytezSecondarySurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

}

/// `!((anchor))` live transclusion (Decision 5, editable in place per
/// `NoteBytez20260829v2-Enhancements.md` Workstream B) — the target block's *current* content,
/// re-resolved every render (`transclusion(for:)`'s "resolve at render time" pattern), in a
/// bordered container with "edit" and "jump to source" buttons. Tapping edit swaps the rendered
/// `Text` for a focused `TextEditor`; committing writes straight through
/// `DocumentViewModel.commitTransclusionEdit` (Decision 6(a): optimistic, last-write-wins — no
/// staleness check, no merge prompt).
///
/// Depth cap 1 without any extra bookkeeping: the target's content is rendered with a single
/// flat `MDProcessor.process(_:)` pass, never by re-running this app's own line-by-line embed
/// scan — so if the target block itself contains a `!((c))`, `MDProcessor` (which treats a
/// `!`-prefixed reference as a plain tappable link, not an image) renders that inner one as an
/// ordinary link, never as a further nested `TransclusionBlockView`/editor. Typing a `!((x))`
/// into the editable text is likewise just characters — nothing here recurses into it (Decision
/// 8's "editable region is that block's text, nothing structural").
private struct TransclusionBlockView: View {

    let anchor: String
    let documentViewModel: DocumentViewModel
    let onJumpToSource: (Document) -> Void

    @State private var isEditing = false
    @State private var draftText = ""
    @FocusState private var isFocused: Bool

    /// Decision 6(a)/7's resolution (Workstream B spike): this codebase has no `UndoManager`
    /// wiring anywhere today (not even for normal document edits — text-field undo is whatever
    /// the platform text view gives you for free while it's focused). Building real
    /// document-model-level undo across two separate `Document`s for this one feature would be
    /// new, disproportionate infrastructure with nothing else in the app to anchor it to. The
    /// achievable, honestly-scoped mitigation: remember the pre-edit text and offer a plain
    /// "Undo edit" action immediately after a commit, which re-commits the old text — same
    /// last-write-wins write path, no new undo primitive.
    @State private var textBeforeLastEdit: String?

    var body: some View {
        if let resolved = documentViewModel.transclusion(for: anchor) {
            VStack(alignment: .leading, spacing: 4) {
                if isEditing {
                    TextEditor(text: $draftText)
                        .font(.body)
                        .frame(minHeight: 60)
                        .focused($isFocused)
                    HStack {
                        Spacer()
                        Button("Cancel") { isEditing = false }
                        Button("Done") {
                            textBeforeLastEdit = resolved.block.content
                            documentViewModel.commitTransclusionEdit(anchor: anchor, newText: draftText)
                            isEditing = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        Text(MDProcessor.process(resolved.block.content ?? ""))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if let previousText = textBeforeLastEdit {
                            Button("Undo Edit") {
                                documentViewModel.commitTransclusionEdit(anchor: anchor, newText: previousText)
                                textBeforeLastEdit = nil
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                        }
                        Button {
                            draftText = resolved.block.content ?? ""
                            isEditing = true
                            isFocused = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Edit transcluded block")
                        Button {
                            onJumpToSource(resolved.document)
                        } label: {
                            Image(systemName: "arrow.up.right")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Jump to source")
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.noteBytezSecondarySurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text(MDProcessor.process("((\(anchor)))"))
                .textSelection(.enabled)
        }
    }

}
