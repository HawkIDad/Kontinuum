// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskDashboardViewModelTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct TaskDashboardViewModelTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func loadAggregatesTasksAcrossDocumentsWithTheirDocumentTitle() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let noteOne = DocumentDAL.create(title: "Sprint Planning", content: "- [ ] Task A", libraryId: libraryId, in: context)
        let noteTwo = DocumentDAL.create(title: "Retro", content: "- [ ] Task B", libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: try #require(noteOne.documentId), libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: try #require(noteTwo.documentId), libraryId: libraryId, in: context)

        let viewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: context)

        #expect(viewModel.dashboardTasks.count == 2)
        #expect(Set(viewModel.dashboardTasks.map { $0.documentTitle }) == ["Sprint Planning", "Retro"])
    }

    @Test func statusFilterOpenExcludesDoneTasks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Open task\n- [x] Done task", libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)

        let viewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: context)
        viewModel.statusFilter = .open

        #expect(viewModel.filteredTasks.map { $0.task.content } == ["Open task"])
    }

    @Test func statusFilterDoneExcludesOpenTasks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Open task\n- [x] Done task", libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)

        let viewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: context)
        viewModel.statusFilter = .done

        #expect(viewModel.filteredTasks.map { $0.task.content } == ["Done task"])
    }

    @Test func statusFilterAllIncludesEverything() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Open task\n- [x] Done task", libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)

        let viewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: context)
        viewModel.statusFilter = .all

        #expect(viewModel.filteredTasks.count == 2)
    }

    @Test func dateFilterOverdueOnlyMatchesPastDueOpenTasks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Overdue task\n- [ ] Future task\n- [ ] No due date", libraryId: libraryId, in: context)
        let tasks = TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)
        tasks[0].dueDate = Date(timeIntervalSince1970: 1_000_000) // long past
        tasks[1].dueDate = Date(timeIntervalSinceNow: 60 * 60 * 24 * 30) // 30 days out

        let viewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: context)
        viewModel.statusFilter = .all
        viewModel.dateFilter = .overdue

        #expect(viewModel.filteredTasks.map { $0.task.content } == ["Overdue task"])
    }

    @Test func dateFilterOverdueExcludesADoneTaskEvenIfPastDue() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [x] Finished late", libraryId: libraryId, in: context)
        let tasks = TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)
        tasks[0].dueDate = Date(timeIntervalSince1970: 1_000_000)

        let viewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: context)
        viewModel.statusFilter = .all
        viewModel.dateFilter = .overdue

        #expect(viewModel.filteredTasks.isEmpty)
    }

    @Test func dateFilterDueTodayMatchesOnlyTodaysTasks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Today\n- [ ] Next month", libraryId: libraryId, in: context)
        let tasks = TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)
        tasks[0].dueDate = Date()
        tasks[1].dueDate = Date(timeIntervalSinceNow: 60 * 60 * 24 * 30)

        let viewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: context)
        viewModel.dateFilter = .dueToday

        #expect(viewModel.filteredTasks.map { $0.task.content } == ["Today"])
    }

    @Test func tagFilterMatchesTheOwningDocumentsTags() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let workNote = DocumentDAL.create(title: "Work", content: "#work\n- [ ] Ship the release", libraryId: libraryId, in: context)
        let workId = try #require(workNote.documentId)
        TagDAL.syncTags(for: workId, content: workNote.content ?? "", libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: workId, libraryId: libraryId, in: context)

        let personalNote = DocumentDAL.create(title: "Personal", content: "#personal\n- [ ] Water plants", libraryId: libraryId, in: context)
        let personalId = try #require(personalNote.documentId)
        TagDAL.syncTags(for: personalId, content: personalNote.content ?? "", libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: personalId, libraryId: libraryId, in: context)

        let viewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: context)
        viewModel.tagFilter = "work"

        #expect(viewModel.filteredTasks.map { $0.task.content } == ["Ship the release"])
    }

    @Test func toggleReloadsAndReflectsTheNewState() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Buy milk", libraryId: libraryId, in: context)
        TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)

        let viewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: context)
        viewModel.statusFilter = .all
        let dashboardTask = try #require(viewModel.dashboardTasks.first)

        viewModel.toggle(dashboardTask)

        #expect(viewModel.dashboardTasks.first?.task.isDone == true)
        #expect(document.content == "- [x] Buy milk")
    }

}
