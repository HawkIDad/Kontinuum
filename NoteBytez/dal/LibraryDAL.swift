// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LibraryDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// Data access layer for `Library`. All reads/writes go through `ModelContext` directly —
/// SwiftData is the local-first source of truth; CloudKit sync happens asynchronously in the
/// background via `SyncEngine` (a manual `CKSyncEngine` wrapper — see `sync/`), never on this path.
enum LibraryDAL {

    private static let selectedLibraryIdKey = "selectedLibraryId"

    static func create(name: String, in context: ModelContext) -> Library {
        let library = Library(name: name)
        context.insert(library)
        if let libraryId = library.libraryId {
            SyncEngine.shared.ensureZone(forLibraryId: libraryId)
            TemplateDAL.seedStarterContent(libraryId: libraryId, in: context)
        }
        return library
    }

    static func fetchActive(in context: ModelContext) -> [Library] {
        let predicate = #Predicate<Library> { $0.isActive == true }
        let descriptor = FetchDescriptor<Library>(predicate: predicate, sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func softDelete(_ library: Library, in context: ModelContext) {
        library.isActive = false
        library.updatedOn = Date()
        SyncEngine.shared.recordChanged(library, in: context)
    }

    static func selectedLibraryId(in defaults: UserDefaults = .standard) -> UUID? {
        guard let idString = defaults.string(forKey: selectedLibraryIdKey) else { return nil }
        return UUID(uuidString: idString)
    }

    static func setSelectedLibraryId(_ libraryId: UUID?, in defaults: UserDefaults = .standard) {
        defaults.set(libraryId?.uuidString, forKey: selectedLibraryIdKey)
    }

}
