// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedViewDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

enum SavedViewDAL {

    @discardableResult
    static func createSearchView(name: String, definition: SavedSearchDefinition, libraryId: UUID, in context: ModelContext) -> SavedView {
        let savedView = SavedView(name: name, libraryId: libraryId, queryType: .search, sortOrder: nextSortOrder(libraryId: libraryId, in: context))
        savedView.searchDefinition = definition
        context.insert(savedView)
        SyncEngine.shared.recordChanged(savedView, in: context)
        return savedView
    }

    @discardableResult
    static func createTaskView(name: String, definition: SavedTaskDefinition, libraryId: UUID, in context: ModelContext) -> SavedView {
        let savedView = SavedView(name: name, libraryId: libraryId, queryType: .task, sortOrder: nextSortOrder(libraryId: libraryId, in: context))
        savedView.taskDefinition = definition
        context.insert(savedView)
        SyncEngine.shared.recordChanged(savedView, in: context)
        return savedView
    }

    @discardableResult
    static func createGraphView(name: String, definition: SavedGraphDefinition, libraryId: UUID, in context: ModelContext) -> SavedView {
        let savedView = SavedView(name: name, libraryId: libraryId, queryType: .graph, sortOrder: nextSortOrder(libraryId: libraryId, in: context))
        savedView.graphDefinition = definition
        context.insert(savedView)
        SyncEngine.shared.recordChanged(savedView, in: context)
        return savedView
    }

    static func fetchActive(libraryId: UUID, in context: ModelContext) -> [SavedView] {
        let predicate = #Predicate<SavedView> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<SavedView>(predicate: predicate, sortBy: [SortDescriptor(\.sortOrder)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func rename(_ savedView: SavedView, to name: String, in context: ModelContext) {
        savedView.name = name
        savedView.updatedOn = Date()
        SyncEngine.shared.recordChanged(savedView, in: context)
    }

    static func delete(_ savedView: SavedView, in context: ModelContext) {
        savedView.isActive = false
        savedView.updatedOn = Date()
        SyncEngine.shared.recordChanged(savedView, in: context)
    }

    /// Commits a full reordering — the caller passes every saved view for the library in its
    /// new desired order; each gets a fresh sequential `sortOrder`. Simpler and less error-prone
    /// than an insert-at-position API, and matches how a `List`'s `.onMove` already hands back
    /// the whole reordered array.
    static func reorder(_ savedViews: [SavedView], in context: ModelContext) {
        for (index, savedView) in savedViews.enumerated() {
            savedView.sortOrder = index
            savedView.updatedOn = Date()
            SyncEngine.shared.recordChanged(savedView, in: context)
        }
    }

    private static func nextSortOrder(libraryId: UUID, in context: ModelContext) -> Int {
        (fetchActive(libraryId: libraryId, in: context).map { $0.sortOrder ?? 0 }.max() ?? -1) + 1
    }

}
