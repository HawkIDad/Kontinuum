// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateGalleryViewModelTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

@MainActor
struct TemplateGalleryViewModelTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Notebook.self, DocumentNotebook.self,
            Property.self, DocumentProperty.self, TemplateGroup.self, NoteTemplate.self,
            NotebookTemplateGroup.self, JournalTemplateGroup.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func aFreshLibraryShowsEveryPackAsNotAdded() throws {
        let viewModel = TemplateGalleryViewModel(libraryId: UUID(), modelContext: try makeContext())
        #expect(viewModel.rows.count == 20)
        #expect(viewModel.rows.allSatisfy { $0.state == .notAdded })
    }

    @Test func addingAPackMovesOnlyThatRowToAdded() throws {
        let context = try makeContext()
        let viewModel = TemplateGalleryViewModel(libraryId: UUID(), modelContext: context)
        let target = try #require(viewModel.rows.first { $0.pack.packId == "software-engineering" }).pack

        viewModel.add(target)

        #expect(viewModel.rows.first { $0.pack.packId == "software-engineering" }?.state == .added)
        #expect(viewModel.rows.filter { $0.state == .notAdded }.count == 19)
    }

    @Test func aStaleAppliedVersionSurfacesUpdateAvailable() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = TemplateGalleryViewModel(libraryId: libraryId, modelContext: context)
        viewModel.add(try #require(viewModel.rows.first { $0.pack.packId == "marketing" }).pack)

        // Simulate the bundled pack having moved ahead of what this library applied.
        let group = try #require(TemplatePackDAL.addedPackGroups(libraryId: libraryId, in: context)
            .first { $0.sourcePackId == "marketing" })
        group.sourcePackVersion = 0
        viewModel.refresh()

        #expect(viewModel.rows.first { $0.pack.packId == "marketing" }?.state == .updateAvailable)
    }

    @Test func searchMatchesOnRoleAlias() throws {
        let viewModel = TemplateGalleryViewModel(libraryId: UUID(), modelContext: try makeContext())
        let matches = viewModel.filteredRows(matching: "business analyst")
        #expect(matches.map(\.pack.packId) == ["product-management"])
    }

    @Test func categoriesAreInTheFixedGalleryOrder() throws {
        let viewModel = TemplateGalleryViewModel(libraryId: UUID(), modelContext: try makeContext())
        #expect(viewModel.categories.first == "Essentials")
        #expect(viewModel.categories.contains("Personal & Creative"))
        #expect(viewModel.categories.firstIndex(of: "Engineering & Data")! < viewModel.categories.firstIndex(of: "People")!)
    }
}
