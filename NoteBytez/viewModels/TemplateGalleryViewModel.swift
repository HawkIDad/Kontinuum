// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateGalleryViewModel.swift
//  Kontinuum
//

import Foundation
import SwiftData
import Observation

/// Drives S28 — the Template Gallery: the bundled Template Packs, each with its
/// added/updatable state for the current library. Per NoteBytez20260824v1-Templates.md Phase 4.
@Observable
final class TemplateGalleryViewModel {

    enum PackState: Equatable {
        case notAdded
        case added
        case updateAvailable
    }

    struct Row: Identifiable {
        let pack: TemplatePackDefinition
        let state: PackState
        var id: String { pack.packId }
    }

    /// Fixed gallery ordering — categories not listed here sort last, alphabetically.
    static let categoryOrder = [
        "Essentials", "Engineering & Data", "Product & Delivery",
        "Go-to-Market", "People", "Governance & Compliance",
        "Food & Hospitality", "Personal & Creative"
    ]

    private(set) var rows: [Row] = []

    let libraryId: UUID
    private let modelContext: ModelContext
    private let bundle: Bundle

    init(libraryId: UUID, modelContext: ModelContext, bundle: Bundle = .main) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        self.bundle = bundle
        refresh()
    }

    func refresh() {
        let packs = TemplatePackDAL.availablePacks(bundle: bundle)
        let addedGroups = TemplatePackDAL.addedPackGroups(libraryId: libraryId, in: modelContext)
        let groupsByPackId = Dictionary(grouping: addedGroups, by: { $0.sourcePackId ?? "" })

        rows = packs.map { pack in
            guard let groups = groupsByPackId[pack.packId], !groups.isEmpty else {
                return Row(pack: pack, state: .notAdded)
            }
            if let active = groups.first(where: { $0.isActive == true }) {
                let state: PackState = TemplatePackDAL.updateAvailable(for: active, bundle: bundle) ? .updateAvailable : .added
                return Row(pack: pack, state: state)
            }
            // Only soft-deleted copies exist — the pack can't be re-added, so show it as added.
            return Row(pack: pack, state: .added)
        }
    }

    var categories: [String] {
        let present = Set(rows.map(\.pack.category))
        let ordered = Self.categoryOrder.filter { present.contains($0) }
        let rest = present.subtracting(ordered).sorted()
        return ordered + rest
    }

    func rows(in category: String) -> [Row] {
        rows.filter { $0.pack.category == category }
    }

    func filteredRows(matching query: String) -> [Row] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return rows }
        return rows.filter { row in
            row.pack.displayName.lowercased().contains(trimmed)
                || row.pack.summary.lowercased().contains(trimmed)
                || row.pack.roleAliases.contains { $0.lowercased().contains(trimmed) }
        }
    }

    func add(_ pack: TemplatePackDefinition) {
        TemplatePackDAL.addPack(pack, libraryId: libraryId, in: modelContext)
        refresh()
    }

    func applyUpdate(_ pack: TemplatePackDefinition) {
        guard let group = TemplatePackDAL.addedPackGroups(libraryId: libraryId, in: modelContext)
            .first(where: { $0.sourcePackId == pack.packId && $0.isActive == true }) else { return }
        TemplatePackDAL.applyUpdate(pack, to: group, libraryId: libraryId, in: modelContext)
        refresh()
    }
}
