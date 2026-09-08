// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedViewViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// Drives S21 (Saved Views) and the "Save this search/query" action on S7/S19. Live
/// re-evaluation (`searchResults`/`taskResults`) never caches a result snapshot — each call
/// re-runs the underlying query fresh, per NoteBytez-ReleaseFeatures.md's "re-evaluates live."
@Observable
final class SavedViewViewModel {

    private(set) var savedViews: [SavedView] = []

    private let libraryId: UUID
    private let modelContext: ModelContext

    init(libraryId: UUID, modelContext: ModelContext) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        load()
    }

    func load() {
        savedViews = SavedViewDAL.fetchActive(libraryId: libraryId, in: modelContext)
    }

    @discardableResult
    func saveSearch(name: String, query: String, scope: SearchViewModel.Scope, isAdvancedMode: Bool) -> SavedView {
        let definition = SavedSearchDefinition(query: query, scope: scope.rawValue, isAdvancedMode: isAdvancedMode)
        let savedView = SavedViewDAL.createSearchView(name: name, definition: definition, libraryId: libraryId, in: modelContext)
        load()
        return savedView
    }

    @discardableResult
    func saveTaskQuery(name: String, statusFilter: TaskDashboardViewModel.StatusFilter, dateFilter: TaskDashboardViewModel.DateFilter, tagFilter: String) -> SavedView {
        let definition = SavedTaskDefinition(statusFilter: statusFilter.rawValue, dateFilter: dateFilter.rawValue, tagFilter: tagFilter)
        let savedView = SavedViewDAL.createTaskView(name: name, definition: definition, libraryId: libraryId, in: modelContext)
        load()
        return savedView
    }

    func rename(_ savedView: SavedView, to name: String) {
        SavedViewDAL.rename(savedView, to: name, in: modelContext)
        load()
    }

    func delete(_ savedView: SavedView) {
        SavedViewDAL.delete(savedView, in: modelContext)
        load()
    }

    func reorder(_ savedViews: [SavedView]) {
        SavedViewDAL.reorder(savedViews, in: modelContext)
        load()
    }

    /// `savedViews` filtered to search-type — the pinned row on S7.
    var savedSearchViews: [SavedView] {
        savedViews.filter { $0.savedQueryType == .search }
    }

    /// `savedViews` filtered to task-type — the pinned row on S19.
    var savedTaskViews: [SavedView] {
        savedViews.filter { $0.savedQueryType == .task }
    }

    func searchResults(for savedView: SavedView) -> [SearchDAL.SearchResult] {
        guard let definition = savedView.searchDefinition, let scope = SearchViewModel.Scope(rawValue: definition.scope) else { return [] }

        if definition.isAdvancedMode {
            return SearchDAL.searchAdvanced(query: definition.query, scope: scope, libraryId: libraryId, in: modelContext)
        }
        switch scope {
        case .content:
            return SearchDAL.searchContent(query: definition.query, libraryId: libraryId, in: modelContext)
        case .tag:
            return SearchDAL.searchByTag(query: definition.query, libraryId: libraryId, in: modelContext)
        case .path:
            return SearchDAL.searchByTitle(query: definition.query, libraryId: libraryId, in: modelContext)
        }
    }

    /// Composes a fresh `TaskDashboardViewModel` configured from the saved filter values,
    /// rather than duplicating `TaskDashboardViewModel`'s filter predicates here — see that
    /// view model's own doc comment.
    func taskResults(for savedView: SavedView) -> [TaskDashboardViewModel.DashboardTask] {
        guard let definition = savedView.taskDefinition else { return [] }

        let dashboardViewModel = TaskDashboardViewModel(libraryId: libraryId, modelContext: modelContext)
        dashboardViewModel.statusFilter = TaskDashboardViewModel.StatusFilter(rawValue: definition.statusFilter) ?? .open
        dashboardViewModel.dateFilter = TaskDashboardViewModel.DateFilter(rawValue: definition.dateFilter) ?? .any
        dashboardViewModel.tagFilter = definition.tagFilter
        return dashboardViewModel.filteredTasks
    }

}
