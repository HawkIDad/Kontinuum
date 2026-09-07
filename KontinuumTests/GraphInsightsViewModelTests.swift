// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphInsightsViewModelTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct GraphInsightsViewModelTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func initialLoadPopulatesEveryCategoryFromTheLibrary() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Orphan", content: "Nothing linked.", libraryId: libraryId, in: context)

        let viewModel = GraphInsightsViewModel(libraryId: libraryId, modelContext: context)

        #expect(viewModel.orphans.map { $0.title } == ["Orphan"])
    }

    @Test func refreshPicksUpChangesMadeSinceTheLastLoad() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target", content: "Nothing.", libraryId: libraryId, in: context)
        let viewModel = GraphInsightsViewModel(libraryId: libraryId, modelContext: context)
        #expect(viewModel.orphans.map { $0.documentId }.contains(target.documentId))

        _ = DocumentDAL.create(title: "Source", content: "See [[Target]].", libraryId: libraryId, in: context)
        viewModel.refresh()

        #expect(!viewModel.orphans.map { $0.documentId }.contains(target.documentId))
    }

    @Test func settingStaleThresholdDaysPersistsAndTriggersARefresh() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Sorta Old", content: "- [ ] Still open", libraryId: libraryId, in: context)
        _ = TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)
        document.updatedOn = Date(timeIntervalSinceNow: -45 * 86400)
        let viewModel = GraphInsightsViewModel(libraryId: libraryId, modelContext: context)
        viewModel.staleThresholdDays = 90

        #expect(!viewModel.staleNotes.map { $0.documentId }.contains(document.documentId))

        viewModel.staleThresholdDays = 30

        #expect(viewModel.staleThresholdDays == 30)
        #expect(GraphInsightsThresholdStore.currentThresholdDays() == 30)
        #expect(viewModel.staleNotes.map { $0.documentId }.contains(document.documentId))
    }

    @Test func clusterGroupsHeadsEachComponentByItsHighestDegreeMember() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let hub = DocumentDAL.create(title: "Hub", content: "[[Leaf One]] [[Leaf Two]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf One", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf Two", content: "", libraryId: libraryId, in: context)

        let viewModel = GraphInsightsViewModel(libraryId: libraryId, modelContext: context)

        let group = try #require(viewModel.clusterGroups.first { $0.members.count == 3 })
        #expect(group.headline.documentId == hub.documentId)
    }

}
