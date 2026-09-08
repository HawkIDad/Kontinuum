// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SearchViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// Drives S7 (Search Results) and S6 (Quick Switcher) — both are just different views onto
/// the same library, so one view model serves both rather than duplicating query state.
@Observable
final class SearchViewModel {

    enum Scope: String, CaseIterable, Identifiable {
        case content = "Content"
        case tag = "Tag"
        case path = "Path"
        var id: String { rawValue }
    }

    var query: String = ""
    var scope: Scope = .content
    /// Phase 5 — Advanced Search: when on, `query` is parsed as a boolean expression
    /// (`AdvancedSearchParser`) instead of a plain per-scope substring match. `scope` still
    /// applies (as the default for non-`#tag` terms — see `SearchDAL.searchAdvanced`), so the
    /// same chips serve both modes rather than a second set of controls.
    var isAdvancedMode: Bool = false
    private(set) var results: [SearchDAL.SearchResult] = []

    /// Not `private` — `SavedViewViewModel` (Phase 7) composes with this view model's own
    /// library/context to save and later re-evaluate a query, rather than threading a separate
    /// `libraryId` parameter through every call site that already holds a `SearchViewModel`.
    let libraryId: UUID
    private let modelContext: ModelContext

    init(libraryId: UUID, modelContext: ModelContext) {
        self.libraryId = libraryId
        self.modelContext = modelContext
    }

    func search() {
        if isAdvancedMode {
            results = SearchDAL.searchAdvanced(query: query, scope: scope, libraryId: libraryId, in: modelContext)
            return
        }
        switch scope {
        case .content:
            results = SearchDAL.searchContent(query: query, libraryId: libraryId, in: modelContext)
        case .tag:
            results = SearchDAL.searchByTag(query: query, libraryId: libraryId, in: modelContext)
        case .path:
            results = SearchDAL.searchByTitle(query: query, libraryId: libraryId, in: modelContext)
        }
    }

    func quickSwitcherResults(query: String) -> [Document] {
        SearchDAL.quickSwitcherMatches(query: query, libraryId: libraryId, in: modelContext)
    }

}
