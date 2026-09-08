// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LibraryViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

@Observable
final class LibraryViewModel {

    private(set) var libraries: [Library] = []
    private(set) var selectedLibrary: Library?

    private let modelContext: ModelContext
    private let defaults: UserDefaults

    init(modelContext: ModelContext, defaults: UserDefaults = .standard) {
        self.modelContext = modelContext
        self.defaults = defaults
        self.loadLibraries()
    }

    func loadLibraries() {
        self.libraries = LibraryDAL.fetchActive(in: self.modelContext)

        if let selectedLibraryId = LibraryDAL.selectedLibraryId(in: self.defaults),
           let library = self.libraries.first(where: { $0.libraryId == selectedLibraryId }) {
            self.selectedLibrary = library
        } else {
            self.selectedLibrary = nil
        }
    }

    func createLibrary(named name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let library = LibraryDAL.create(name: trimmedName, in: self.modelContext)
        self.loadLibraries()
        self.select(library)
    }

    /// Creates a library without selecting it — used for the import flow, where S2's scan
    /// still needs a chance to cancel (soft-deleting the library) before the user ever lands
    /// in it.
    func createLibraryForImport(named name: String) -> Library {
        let library = LibraryDAL.create(name: name, in: self.modelContext)
        self.loadLibraries()
        return library
    }

    func select(_ library: Library) {
        LibraryDAL.setSelectedLibraryId(library.libraryId, in: self.defaults)
        self.selectedLibrary = library
    }

    func delete(_ library: Library) {
        let isDeletingSelectedLibrary = self.selectedLibrary?.libraryId == library.libraryId
        LibraryDAL.softDelete(library, in: self.modelContext)

        if isDeletingSelectedLibrary {
            LibraryDAL.setSelectedLibraryId(nil, in: self.defaults)
        }

        self.loadLibraries()
    }

}
