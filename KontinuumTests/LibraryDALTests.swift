// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LibraryDALTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct LibraryDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, TemplateGroup.self, NoteTemplate.self, NotebookTemplateGroup.self, JournalTemplateGroup.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "LibraryDALTests-\(UUID().uuidString)")!
        return defaults
    }

    @Test func fetchActiveOnEmptyContextReturnsEmptyList() throws {
        let context = try makeContext()
        #expect(LibraryDAL.fetchActive(in: context).isEmpty)
    }

    @Test func createInsertsActiveLibraryWithName() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Personal", in: context)

        #expect(library.name == "Personal")
        #expect(library.isActive == true)
        #expect(library.libraryId != nil)

        let fetched = LibraryDAL.fetchActive(in: context)
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Personal")
    }

    @Test func softDeleteExcludesLibraryFromFetchActive() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Work", in: context)

        LibraryDAL.softDelete(library, in: context)

        #expect(library.isActive == false)
        #expect(LibraryDAL.fetchActive(in: context).isEmpty)
    }

    @Test func softDeleteDoesNotRemoveTheRecord() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Work", in: context)
        let libraryId = library.libraryId

        LibraryDAL.softDelete(library, in: context)

        let descriptor = FetchDescriptor<Library>()
        let allLibraries = try context.fetch(descriptor)
        #expect(allLibraries.count == 1)
        #expect(allLibraries.first?.libraryId == libraryId)
    }

    /// `LibraryDAL.create` calls `TemplateDAL.seedStarterContent` (Phase 3) — this is the
    /// wiring test proving a brand-new library actually gets the starter TemplateGroups, not
    /// just that `seedStarterContent` works when called directly (see `TemplateDALTests`).
    @Test func createSeedsStarterTemplateGroups() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Personal", in: context)
        let libraryId = try #require(library.libraryId)

        let groups = TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context)
        #expect(Set(groups.compactMap { $0.name }) == ["Fiction Writing", "Wedding Planning", "Photography Client Work"])
    }

    @Test func selectedLibraryIdRoundTripsThroughDefaults() {
        let defaults = makeDefaults()
        let libraryId = UUID()

        #expect(LibraryDAL.selectedLibraryId(in: defaults) == nil)

        LibraryDAL.setSelectedLibraryId(libraryId, in: defaults)
        #expect(LibraryDAL.selectedLibraryId(in: defaults) == libraryId)

        LibraryDAL.setSelectedLibraryId(nil, in: defaults)
        #expect(LibraryDAL.selectedLibraryId(in: defaults) == nil)
    }

}
