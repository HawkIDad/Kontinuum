// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedViewDALTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct SavedViewDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, SavedView.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - CRUD

    @Test func createSearchViewStoresItsDefinition() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let definition = SavedSearchDefinition(query: "#character AND #act2", scope: "Content", isAdvancedMode: true)

        let savedView = SavedViewDAL.createSearchView(name: "Act 2 Antagonists", definition: definition, libraryId: libraryId, in: context)

        #expect(savedView.savedQueryType == .search)
        #expect(savedView.searchDefinition == definition)
        #expect(SavedViewDAL.fetchActive(libraryId: libraryId, in: context).count == 1)
    }

    @Test func createTaskViewStoresItsDefinition() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let definition = SavedTaskDefinition(statusFilter: "Open", dateFilter: "Overdue", tagFilter: "work")

        let savedView = SavedViewDAL.createTaskView(name: "Overdue Work", definition: definition, libraryId: libraryId, in: context)

        #expect(savedView.savedQueryType == .task)
        #expect(savedView.taskDefinition == definition)
    }

    @Test func createGraphViewStoresItsFilterSet() throws {
        let context = try makeContext()
        let libraryId = UUID()
        var filter = GraphFilter()
        filter.depth = 2
        filter.showOrphans = false
        filter.tagScope = "worldbuilding"
        let definition = SavedGraphDefinition(focusDocumentId: UUID(), filter: filter)

        let savedView = SavedViewDAL.createGraphView(name: "Worldbuilding Map", definition: definition, libraryId: libraryId, in: context)

        #expect(savedView.savedQueryType == .graph)
        #expect(savedView.graphDefinition == definition)
    }

    @Test func fetchActiveOrdersBySortOrder() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let first = SavedViewDAL.createSearchView(name: "First", definition: SavedSearchDefinition(query: "a", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)
        let second = SavedViewDAL.createSearchView(name: "Second", definition: SavedSearchDefinition(query: "b", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)

        let fetched = SavedViewDAL.fetchActive(libraryId: libraryId, in: context)

        #expect(fetched.map { $0.savedViewId } == [first.savedViewId, second.savedViewId])
    }

    @Test func fetchActiveExcludesOtherLibraries() throws {
        let context = try makeContext()
        SavedViewDAL.createSearchView(name: "Mine", definition: SavedSearchDefinition(query: "a", scope: "Content", isAdvancedMode: false), libraryId: UUID(), in: context)

        #expect(SavedViewDAL.fetchActive(libraryId: UUID(), in: context).isEmpty)
    }

    @Test func renameUpdatesTheName() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let savedView = SavedViewDAL.createSearchView(name: "Old Name", definition: SavedSearchDefinition(query: "a", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)

        SavedViewDAL.rename(savedView, to: "New Name", in: context)

        #expect(savedView.name == "New Name")
    }

    @Test func deleteSoftDeletesRatherThanRemoving() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let savedView = SavedViewDAL.createSearchView(name: "Gone Soon", definition: SavedSearchDefinition(query: "a", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)

        SavedViewDAL.delete(savedView, in: context)

        #expect(savedView.isActive == false)
        #expect(SavedViewDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)
        let allRecords = try context.fetch(FetchDescriptor<SavedView>())
        #expect(allRecords.count == 1)
    }

    // MARK: - reorder

    @Test func reorderReassignsSequentialSortOrderInTheGivenOrder() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let first = SavedViewDAL.createSearchView(name: "First", definition: SavedSearchDefinition(query: "a", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)
        let second = SavedViewDAL.createSearchView(name: "Second", definition: SavedSearchDefinition(query: "b", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)
        let third = SavedViewDAL.createSearchView(name: "Third", definition: SavedSearchDefinition(query: "c", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)

        SavedViewDAL.reorder([third, first, second], in: context)

        let fetched = SavedViewDAL.fetchActive(libraryId: libraryId, in: context)
        #expect(fetched.map { $0.savedViewId } == [third.savedViewId, first.savedViewId, second.savedViewId])
    }

    @Test func newSavedViewsAppendAfterExistingOnes() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let first = SavedViewDAL.createSearchView(name: "First", definition: SavedSearchDefinition(query: "a", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)
        let second = SavedViewDAL.createSearchView(name: "Second", definition: SavedSearchDefinition(query: "b", scope: "Content", isAdvancedMode: false), libraryId: libraryId, in: context)

        #expect((first.sortOrder ?? -1) < (second.sortOrder ?? -1))
    }

}
