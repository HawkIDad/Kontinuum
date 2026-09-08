// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct TaskDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func syncTasksCreatesOneRowPerCheckboxLine() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] First\n- [x] Second", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let tasks = TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)

        #expect(tasks.count == 2)
        #expect(tasks.map { $0.content } == ["First", "Second"])
        #expect(tasks.map { $0.isDone } == [false, true])
        #expect(tasks.allSatisfy { $0.blockId != nil })
    }

    @Test func syncTasksReusesExistingRowOnResync() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] First", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        let first = TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)
        let second = TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)

        #expect(first.first?.taskItemId == second.first?.taskItemId)
        #expect(TaskDAL.fetchActive(documentId: documentId, in: context).count == 1)
    }

    @Test func syncTasksSoftDeletesARemovedTask() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] First\n- [ ] Second", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)
        DocumentDAL.updateContent(document, content: "- [ ] First", in: context)
        TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)

        let remaining = TaskDAL.fetchActive(documentId: documentId, in: context)
        #expect(remaining.count == 1)
        #expect(remaining.first?.content == "First")
    }

    // MARK: - Cross-note aggregation (Phase 6)

    @Test func fetchActiveByLibraryAggregatesTasksAcrossEveryDocument() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let noteOne = DocumentDAL.create(title: "One", content: "- [ ] Task A", libraryId: libraryId, in: context)
        let noteTwo = DocumentDAL.create(title: "Two", content: "- [ ] Task B", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Other Library", content: "- [ ] Should not appear", libraryId: UUID(), in: context)
        TaskDAL.syncTasks(for: try #require(noteOne.documentId), libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: try #require(noteTwo.documentId), libraryId: libraryId, in: context)

        let tasks = TaskDAL.fetchActive(libraryId: libraryId, in: context)

        #expect(Set(tasks.map { $0.content }) == ["Task A", "Task B"])
    }

    // MARK: - toggle(_:in:) — the Task Dashboard's own toggle path

    @Test func toggleFlipsTheTaskAndPersistsThroughDocumentContent() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Buy milk", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let task = try #require(TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context).first)

        let succeeded = TaskDAL.toggle(task, in: context)

        #expect(succeeded)
        #expect(document.content == "- [x] Buy milk")
        #expect(TaskDAL.fetchActive(documentId: documentId, in: context).first?.isDone == true)
    }

    @Test func toggleThroughDashboardAndThroughDocumentViewModelProduceIdenticalPersistedState() throws {
        // Two documents, same starting content, toggled via each of the two entry points —
        // both must land on the same on-disk state, per this phase's "same toggle path"
        // consistency guarantee.
        let context = try makeContext()
        let libraryId = UUID()

        let viaDocument = DocumentDAL.create(title: "Via Document", content: "- [ ] Buy milk", libraryId: libraryId, in: context)
        DocumentViewModel(document: viaDocument, modelContext: context).toggleTask(at: 0)

        let viaDashboard = DocumentDAL.create(title: "Via Dashboard", content: "- [ ] Buy milk", libraryId: libraryId, in: context)
        let dashboardDocumentId = try #require(viaDashboard.documentId)
        let dashboardTask = try #require(TaskDAL.syncTasks(for: dashboardDocumentId, libraryId: libraryId, in: context).first)
        TaskDAL.toggle(dashboardTask, in: context)

        #expect(viaDocument.content == viaDashboard.content)
        #expect(TaskDAL.fetchActive(documentId: try #require(viaDocument.documentId), in: context).first?.isDone
            == TaskDAL.fetchActive(documentId: dashboardDocumentId, in: context).first?.isDone)
    }

    @Test func toggleReturnsFalseWithoutCrashingIfTheBlockNoLongerMatches() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Buy milk", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let task = try #require(TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context).first)

        // The document changed elsewhere since the dashboard last loaded this task.
        DocumentDAL.updateContent(document, content: "Completely different content now.", in: context)

        #expect(!TaskDAL.toggle(task, in: context))
    }

    // MARK: - Recurrence advancement (Phase 6)

    @Test func completingARecurringTaskAdvancesItsDueDateAndStaysDone() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Water the plants", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let task = try #require(TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context).first)
        let startDate = Date(timeIntervalSince1970: 1_000_000)
        task.dueDate = startDate
        task.recurrenceRule = RecurrenceRule.weekly.rawValue

        TaskDAL.toggle(task, in: context)

        let updated = try #require(TaskDAL.fetchActive(documentId: documentId, in: context).first)
        #expect(updated.isDone == true)
        #expect(updated.dueDate == RecurrenceRule.weekly.nextOccurrence(after: startDate))
    }

    @Test func resyncingAnAlreadyDoneRecurringTaskDoesNotReadvanceTheDueDate() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [x] Water the plants", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let task = try #require(TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context).first)
        let dueDate = Date(timeIntervalSince1970: 1_000_000)
        task.dueDate = dueDate
        task.recurrenceRule = RecurrenceRule.weekly.rawValue

        // Re-saving the same already-done content (e.g. an unrelated edit elsewhere in the
        // document) must not treat this as a fresh completion.
        TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)

        #expect(task.dueDate == dueDate)
    }

    @Test func completingANonRecurringTaskLeavesDueDateUntouched() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] One-off errand", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let task = try #require(TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context).first)
        let dueDate = Date(timeIntervalSince1970: 1_000_000)
        task.dueDate = dueDate

        TaskDAL.toggle(task, in: context)

        #expect(task.dueDate == dueDate)
    }

    /// Regression test for a real bug found while building Phase 6 (Task Dashboards): toggling
    /// a checkbox changes that block's content, and `BlockDAL.syncBlocks` deliberately assigns
    /// a *new* `blockId` for any block whose content changed at all — so a `TaskItem` reuse key
    /// built from `blockId` broke on every single toggle, silently discarding whatever
    /// due-date/priority/recurrence had been set (a fresh row with none of that carried over).
    /// Invisible in MVP since those fields were reserved but never surfaced; a real data-loss
    /// bug now that they are. `syncTasks` keys reuse by the block's *position* instead.
    @Test func syncTasksPreservesTaskItemIdentityAndCustomFieldsAcrossAToggle() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Buy milk", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let original = try #require(TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context).first)
        let originalTaskItemId = original.taskItemId
        let originalBlockId = original.blockId
        original.priority = 1
        original.dueDate = Date(timeIntervalSince1970: 1_000_000)

        DocumentDAL.updateContent(document, content: "- [x] Buy milk", in: context)
        let resynced = try #require(TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context).first)

        // Feature B (sticky identity): the marker flip reclaims the same Block (same position,
        // near-identical text), so the blockId is stable here too — `reuseKey`'s position+text
        // keying below no longer needs to route around a churning blockId to make this pass,
        // but keeps working unchanged since it never depended on blockId in the first place.
        #expect(resynced.blockId == originalBlockId)
        // The TaskItem row — and its user-set fields — survived regardless.
        #expect(resynced.taskItemId == originalTaskItemId)
        #expect(resynced.priority == 1)
        #expect(resynced.dueDate == Date(timeIntervalSince1970: 1_000_000))
        #expect(resynced.isDone == true)
    }

    @Test func fetchActiveReturnsEmptyForADocumentWithNoTasks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "Just plain text.", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)

        TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)

        #expect(TaskDAL.fetchActive(documentId: documentId, in: context).isEmpty)
    }

    // MARK: - Toggle persistence + greppability, via DocumentViewModel (S3/S4's shared path)

    @Test func togglingTaskThroughDocumentViewModelPersistsTheStateChange() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Buy milk", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: document, modelContext: context)
        viewModel.toggleTask(at: 0)

        #expect(viewModel.content == "- [x] Buy milk")
        #expect(document.content == "- [x] Buy milk")

        let documentId = try #require(document.documentId)
        let tasks = TaskDAL.fetchActive(documentId: documentId, in: context)
        #expect(tasks.first?.isDone == true)
    }

    @Test func togglingTaskSurvivesReloadingTheDocumentViewModelFromPersistedState() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Buy milk", libraryId: libraryId, in: context)

        DocumentViewModel(document: document, modelContext: context).toggleTask(at: 0)

        // Simulates reopening the note (a fresh DocumentViewModel, as S3<->S4 navigation does).
        let reloaded = DocumentViewModel(document: document, modelContext: context)
        #expect(reloaded.content == "- [x] Buy milk")
        #expect(reloaded.tasks.first?.isDone == true)
    }

    @Test func togglingTaskKeepsContentAsPlainGreppableMarkdown() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Review PR from [[Dana]] #standup", libraryId: libraryId, in: context)

        let viewModel = DocumentViewModel(document: document, modelContext: context)
        viewModel.toggleTask(at: 0)

        #expect(viewModel.content.contains("- [x] Review PR from [[Dana]] #standup"))
        #expect(viewModel.content.hasPrefix("- ["))
    }

}
