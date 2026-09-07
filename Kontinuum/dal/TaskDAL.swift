// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

enum TaskDAL {

    static func fetchActive(documentId: UUID, in context: ModelContext) -> [TaskItem] {
        let predicate = #Predicate<TaskItem> { $0.documentId == documentId && $0.isActive == true }
        let descriptor = FetchDescriptor<TaskItem>(predicate: predicate, sortBy: [SortDescriptor(\.createdOn)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Every active task across the whole library, regardless of which document it lives in —
    /// the Task Dashboard's (Phase 6) cross-note query. Unlike `Block`, `TaskItem` already
    /// carries its own `libraryId` (set at creation in `syncTasks` below), so this is a direct
    /// predicate fetch, not a join through `DocumentDAL` the way `BlockDAL`'s equivalent needed.
    static func fetchActive(libraryId: UUID, in context: ModelContext) -> [TaskItem] {
        let predicate = #Predicate<TaskItem> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<TaskItem>(predicate: predicate, sortBy: [SortDescriptor(\.createdOn)])
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Toggles `task`'s checkbox by locating and flipping the specific `Block` it lives in,
    /// rather than `DocumentViewModel.toggleTask(at:)`'s whole-document-content index — that
    /// index only makes sense for a document already loaded and being edited in place (S3/S4);
    /// the Task Dashboard (S19) reaches an arbitrary task from any document without one open.
    /// Mirrors `NotebookDAL.appendBackLink`'s block-splice approach: locate the block by its
    /// `sortOrder` position among the document's current chunks, verify it still matches before
    /// touching it (a no-op, not a crash, if the document was edited elsewhere since this task
    /// was last indexed), then delegate to the same `TaskParser.toggling`/`syncTasks` machinery
    /// S3/S4 already use — same underlying flip-and-reconcile path, just reached differently.
    @discardableResult
    static func toggle(_ task: TaskItem, in context: ModelContext) -> Bool {
        guard let documentId = task.documentId,
              let libraryId = task.libraryId,
              let blockId = task.blockId,
              let taskText = task.content,
              let document = Document.fetch(syncId: documentId, in: context),
              let documentContent = document.content,
              let block = Block.fetch(syncId: blockId, in: context),
              let blockContent = block.content,
              let sortOrder = block.sortOrder
        else { return false }

        var chunks = MarkdownBlockSplitter.split(documentContent)
        guard chunks.indices.contains(sortOrder), chunks[sortOrder] == blockContent else { return false }

        guard let taskIndexInBlock = TaskParser.extractTasks(from: blockContent).firstIndex(where: { $0.text == taskText }) else { return false }

        chunks[sortOrder] = TaskParser.toggling(taskIndex: taskIndexInBlock, in: blockContent)
        DocumentDAL.updateContent(document, content: MarkdownBlockSplitter.join(chunks), in: context)
        syncTasks(for: documentId, libraryId: libraryId, in: context)
        return true
    }

    /// Re-parses each active `Block`'s content for checkbox lines and reconciles `TaskItem`
    /// rows against them: a line whose (block position, text) matches an existing active row
    /// reuses that row (so its `taskItemId` — and its due-date/priority/recurrence — survives
    /// across edits); unmatched rows are soft-deleted, new lines become new rows.
    ///
    /// Keyed by the owning block's *position* (`Block.sortOrder`), not its `blockId`.
    /// `BlockDAL.syncBlocks` assigns a block a brand-new `blockId` whenever its content changes
    /// at all (per its own "even a small edit is a removal+insertion" reuse rule) — and every
    /// checkbox toggle changes a block's content by definition, since the marker itself is part
    /// of that content. Keying reuse by `blockId` therefore silently orphaned the `TaskItem` row
    /// (and whatever due-date/priority/recurrence the user had set on it) on *every single
    /// toggle* — invisible in MVP since those fields were reserved but never surfaced, and a
    /// real, user-facing data-loss bug now that Phase 6 surfaces them. A block's *position*
    /// stays stable across a pure marker flip (the chunk doesn't move, only its text changes),
    /// so that's the part of a block's identity this reuse actually needs.
    @discardableResult
    static func syncTasks(for documentId: UUID, libraryId: UUID, in context: ModelContext) -> [TaskItem] {
        let blocks = BlockDAL.fetchActive(documentId: documentId, in: context)

        let predicate = #Predicate<TaskItem> { $0.documentId == documentId && $0.isActive == true }
        let existingTasks = (try? context.fetch(FetchDescriptor<TaskItem>(predicate: predicate))) ?? []

        var availableByKey: [String: [TaskItem]] = [:]
        for task in existingTasks {
            // The task's original block may have just been soft-deleted by this same save
            // (see above) — `Block.fetch` still finds it; only its `isActive` flag changed.
            let originalSortOrder = task.blockId.flatMap { Block.fetch(syncId: $0, in: context)?.sortOrder }
            availableByKey[reuseKey(sortOrder: originalSortOrder, text: task.content ?? ""), default: []].append(task)
        }

        var resultTasks: [TaskItem] = []
        var consumedTaskIds: Set<UUID> = []

        for block in blocks {
            guard let blockId = block.blockId, let sortOrder = block.sortOrder else { continue }
            for match in TaskParser.extractTasks(from: block.content ?? "") {
                let key = reuseKey(sortOrder: sortOrder, text: match.text)
                if var candidates = availableByKey[key], !candidates.isEmpty {
                    let reused = candidates.removeFirst()
                    availableByKey[key] = candidates

                    let wasDone = reused.isDone ?? false
                    reused.isDone = match.isDone
                    // The reused row may now belong to a *different* block than before (see
                    // this function's own doc comment) — keep the FK current so a later
                    // `toggle(_:in:)` call locates the right block, not a stale/soft-deleted one.
                    reused.blockId = blockId
                    reused.updatedOn = Date()
                    if !wasDone, match.isDone {
                        advanceRecurrenceIfNeeded(reused)
                    }
                    resultTasks.append(reused)
                    if let taskItemId = reused.taskItemId {
                        consumedTaskIds.insert(taskItemId)
                    }
                } else {
                    let task = TaskItem(content: match.text, isDone: match.isDone, documentId: documentId, blockId: blockId, libraryId: libraryId)
                    context.insert(task)
                    resultTasks.append(task)
                }
            }
        }

        for task in existingTasks {
            guard let taskItemId = task.taskItemId, !consumedTaskIds.contains(taskItemId) else { continue }
            task.isActive = false
            task.updatedOn = Date()
            SyncEngine.shared.recordChanged(task, in: context)
        }

        for task in resultTasks {
            SyncEngine.shared.recordChanged(task, in: context)
        }

        return resultTasks
    }

    private static func reuseKey(sortOrder: Int?, text: String) -> String {
        "\(sortOrder.map(String.init) ?? "")|\(text)"
    }

    /// Advances a just-completed recurring task's `dueDate` to its next occurrence, leaving
    /// `isDone = true` — this occurrence is genuinely done; `dueDate` now shows when it's due
    /// again, rather than auto-reopening the same row. Safe to mutate directly (unlike
    /// `isDone`, `dueDate`/`priority`/`recurrenceRule` have no Markdown representation at all in
    /// this app — see `NoteBytez-ReleaseFeatures.md`'s Decisions Log — so there's no content to
    /// keep in sync). Fires exactly once per real done-transition: the caller only invokes this
    /// when `isDone` just flipped from false to true, never on a resync of an already-done task.
    private static func advanceRecurrenceIfNeeded(_ task: TaskItem) {
        guard let rawRule = task.recurrenceRule, let rule = RecurrenceRule(rawValue: rawRule) else { return }
        task.dueDate = rule.nextOccurrence(after: task.dueDate ?? Date())
    }

}
