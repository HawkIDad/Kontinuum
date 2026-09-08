// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagViewModel.swift
//  Kontinuum
//

import Foundation
import SwiftData
import Observation

@Observable
final class TagViewModel {

    struct TagSummary: Identifiable {
        let tag: Tag
        let noteCount: Int
        var id: UUID { tag.tagId ?? UUID() }
    }

    private(set) var tagSummaries: [TagSummary] = []

    private let libraryId: UUID
    private let modelContext: ModelContext

    init(libraryId: UUID, modelContext: ModelContext) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        self.load()
    }

    func load() {
        tagSummaries = TagDAL.fetchActive(libraryId: libraryId, in: modelContext).map { tag in
            TagSummary(tag: tag, noteCount: TagDAL.fetchDocuments(for: tag, in: modelContext).count)
        }
    }

    func documents(for tag: Tag) -> [Document] {
        TagDAL.fetchDocuments(for: tag, in: modelContext)
    }

}
