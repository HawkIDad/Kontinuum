// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// Drives S2 (Import Scan & Confirm) for a library that's already been created (optimistically,
/// by the caller) but not yet selected — `confirmImport` populates it and leaves selection to
/// the caller; `cancelImport` soft-deletes it so an aborted import leaves no empty library
/// behind.
@Observable
final class ImportViewModel {

    let library: Library
    private(set) var files: [ImportFileSummary]

    private let modelContext: ModelContext

    init(library: Library, folderURL: URL, modelContext: ModelContext) {
        self.library = library
        self.modelContext = modelContext
        self.files = ImportScanner.scan(folderURL: folderURL)
    }

    var noteCount: Int { files.count }
    var linkCount: Int { files.reduce(0) { $0 + $1.linkCount } }
    var taskCount: Int { files.reduce(0) { $0 + $1.taskCount } }
    /// Distinct notebook names detected across every file — reflects only files carrying a
    /// `notebooks:` frontmatter field (i.e. previously exported by NoteBytez), not an
    /// inference from a foreign vault's own tag conventions.
    var notebookCount: Int { Set(files.flatMap { $0.notebookNames }).count }

    /// Auto-snapshots before committing anything, per Journey 1 — if the import goes wrong,
    /// S12's restore flow needs the library's pre-import state to still exist.
    func confirmImport() {
        guard let libraryId = library.libraryId else { return }
        BackupDAL.createSnapshot(cause: .automatic, in: modelContext)
        ImportDAL.importFiles(files, libraryId: libraryId, in: modelContext)
    }

    func cancelImport() {
        LibraryDAL.softDelete(library, in: modelContext)
    }

}
