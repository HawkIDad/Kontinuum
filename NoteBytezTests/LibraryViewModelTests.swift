// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LibraryViewModelTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct LibraryViewModelTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "LibraryViewModelTests-\(UUID().uuidString)")!
        defaults.removePersistentDomain(forName: defaults.description)
        return defaults
    }

    @Test func loadLibrariesStartsWithNoSelectionWhenNoneIsStored() throws {
        let context = try makeContext()
        let viewModel = LibraryViewModel(modelContext: context, defaults: makeDefaults())

        #expect(viewModel.libraries.isEmpty)
        #expect(viewModel.selectedLibrary == nil)
    }

    @Test func createLibraryTrimsWhitespaceAndSelectsIt() throws {
        let context = try makeContext()
        let viewModel = LibraryViewModel(modelContext: context, defaults: makeDefaults())

        viewModel.createLibrary(named: "  My Library  ")

        #expect(viewModel.libraries.map { $0.name } == ["My Library"])
        #expect(viewModel.selectedLibrary?.name == "My Library")
    }

    @Test func createLibraryIsANoOpForBlankInput() throws {
        let context = try makeContext()
        let viewModel = LibraryViewModel(modelContext: context, defaults: makeDefaults())

        viewModel.createLibrary(named: "   ")

        #expect(viewModel.libraries.isEmpty)
        #expect(viewModel.selectedLibrary == nil)
    }

    @Test func createLibraryForImportDoesNotSelectIt() throws {
        let context = try makeContext()
        let viewModel = LibraryViewModel(modelContext: context, defaults: makeDefaults())

        let imported = viewModel.createLibraryForImport(named: "Imported Vault")

        #expect(viewModel.libraries.map { $0.name } == ["Imported Vault"])
        #expect(viewModel.selectedLibrary == nil)
        #expect(imported.name == "Imported Vault")
    }

    @Test func loadLibrariesRestoresAPreviouslySelectedLibrary() throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        let firstViewModel = LibraryViewModel(modelContext: context, defaults: defaults)
        firstViewModel.createLibrary(named: "Mine")

        let secondViewModel = LibraryViewModel(modelContext: context, defaults: defaults)
        #expect(secondViewModel.selectedLibrary?.name == "Mine")
    }

    @Test func deletingTheSelectedLibraryClearsTheSelection() throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        let viewModel = LibraryViewModel(modelContext: context, defaults: defaults)
        viewModel.createLibrary(named: "Mine")
        let library = try #require(viewModel.selectedLibrary)

        viewModel.delete(library)

        #expect(viewModel.libraries.isEmpty)
        #expect(viewModel.selectedLibrary == nil)
        #expect(LibraryDAL.selectedLibraryId(in: defaults) == nil)
    }

    @Test func deletingAnUnselectedLibraryLeavesTheSelectionAlone() throws {
        let context = try makeContext()
        let viewModel = LibraryViewModel(modelContext: context, defaults: makeDefaults())
        viewModel.createLibrary(named: "Keep Me")
        let kept = try #require(viewModel.selectedLibrary)
        let other = viewModel.createLibraryForImport(named: "Delete Me")

        viewModel.delete(other)

        #expect(viewModel.selectedLibrary?.libraryId == kept.libraryId)
    }

}
