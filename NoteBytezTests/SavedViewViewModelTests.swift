// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedViewViewModelTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct SavedViewViewModelTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, TaskItem.self, SavedView.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - Save + round trip

    @Test func saveSearchRoundTripsQueryScopeAndAdvancedMode() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = SavedViewViewModel(libraryId: libraryId, modelContext: context)

        let savedView = viewModel.saveSearch(name: "Act 2 Antagonists", query: "#character AND #act2", scope: .content, isAdvancedMode: true)

        #expect(savedView.searchDefinition == SavedSearchDefinition(query: "#character AND #act2", scope: "Content", isAdvancedMode: true))
        #expect(viewModel.savedViews.map { $0.savedViewId }.contains(savedView.savedViewId))
    }

    @Test func saveTaskQueryRoundTripsAllThreeFilters() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = SavedViewViewModel(libraryId: libraryId, modelContext: context)

        let savedView = viewModel.saveTaskQuery(name: "Overdue Work", statusFilter: .open, dateFilter: .overdue, tagFilter: "work")

        #expect(savedView.taskDefinition == SavedTaskDefinition(statusFilter: "Open", dateFilter: "Overdue", tagFilter: "work"))
    }

    @Test func savedSearchViewsAndSavedTaskViewsPartitionByType() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = SavedViewViewModel(libraryId: libraryId, modelContext: context)
        viewModel.saveSearch(name: "A Search", query: "a", scope: .content, isAdvancedMode: false)
        viewModel.saveTaskQuery(name: "A Task View", statusFilter: .open, dateFilter: .any, tagFilter: "")

        #expect(viewModel.savedSearchViews.map { $0.name } == ["A Search"])
        #expect(viewModel.savedTaskViews.map { $0.name } == ["A Task View"])
    }

    // MARK: - Live re-evaluation (never a frozen snapshot)

    @Test func searchResultsReflectDocumentsCreatedAfterTheViewWasSaved() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = SavedViewViewModel(libraryId: libraryId, modelContext: context)
        let savedView = viewModel.saveSearch(name: "Roadmap Notes", query: "roadmap", scope: .content, isAdvancedMode: false)

        #expect(viewModel.searchResults(for: savedView).isEmpty)

        // A document matching the saved query is created *after* the view was saved.
        _ = DocumentDAL.create(title: "Q4 Roadmap", content: "Planning notes.", libraryId: libraryId, in: context)

        #expect(viewModel.searchResults(for: savedView).count == 1)
    }

    @Test func searchResultsStopMatchingOnceADocumentNoLongerDoes() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Q4 Roadmap", content: "", libraryId: libraryId, in: context)
        let viewModel = SavedViewViewModel(libraryId: libraryId, modelContext: context)
        let savedView = viewModel.saveSearch(name: "Roadmap Notes", query: "roadmap", scope: .path, isAdvancedMode: false)
        #expect(viewModel.searchResults(for: savedView).count == 1)

        DocumentDAL.updateTitle(document, title: "Renamed Away", in: context)

        #expect(viewModel.searchResults(for: savedView).isEmpty)
    }

    @Test func taskResultsReflectATaskCompletedAfterTheViewWasSaved() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Note", content: "- [ ] Buy milk", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)

        let viewModel = SavedViewViewModel(libraryId: libraryId, modelContext: context)
        let savedView = viewModel.saveTaskQuery(name: "Open Tasks", statusFilter: .open, dateFilter: .any, tagFilter: "")
        #expect(viewModel.taskResults(for: savedView).count == 1)

        let task = try #require(TaskDAL.fetchActive(documentId: documentId, in: context).first)
        TaskDAL.toggle(task, in: context)

        // The task is now done, so it drops out of the "Open" saved view live, without
        // re-saving or re-creating the SavedView.
        #expect(viewModel.taskResults(for: savedView).isEmpty)
    }

    @Test func searchResultsForAdvancedModeUseTheBooleanQueryParser() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let match = DocumentDAL.create(title: "Elyra", content: "", libraryId: libraryId, in: context)
        let matchId = try #require(match.documentId)
        TagDAL.syncTags(for: matchId, content: "#character #act2", libraryId: libraryId, in: context)
        let nonMatch = DocumentDAL.create(title: "Other", content: "", libraryId: libraryId, in: context)
        TagDAL.syncTags(for: try #require(nonMatch.documentId), content: "#character", libraryId: libraryId, in: context)

        let viewModel = SavedViewViewModel(libraryId: libraryId, modelContext: context)
        let savedView = viewModel.saveSearch(name: "Act 2 Characters", query: "#character AND #act2", scope: .content, isAdvancedMode: true)

        let results = viewModel.searchResults(for: savedView)
        #expect(results.count == 1)
        #expect(results.first?.document.documentId == matchId)
    }

    // MARK: - Delete / reorder reload state

    @Test func deleteRemovesTheSavedViewFromTheLoadedList() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = SavedViewViewModel(libraryId: libraryId, modelContext: context)
        let savedView = viewModel.saveSearch(name: "Temp", query: "a", scope: .content, isAdvancedMode: false)

        viewModel.delete(savedView)

        #expect(viewModel.savedViews.isEmpty)
    }

}
