// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateOnboardingViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// Drives the first-run role picker. Offers the knowledge-management packs (not the creative
/// starters, which `LibraryDAL.create` already seeds); selecting any of them also adds the
/// Common / KM Essentials pack. Per NoteBytez20260824v1-Templates.md Phase 5.
@Observable
final class TemplateOnboardingViewModel {

    static let commonPackId = "common-km-essentials"
    /// Above this many selected packs, the view confirms before adding (R7).
    static let bulkAddThreshold = 4

    struct Choice: Identifiable {
        let pack: TemplatePackDefinition
        var isSelected: Bool
        var id: String { pack.packId }
    }

    private(set) var choices: [Choice]

    private let libraryId: UUID
    private let modelContext: ModelContext
    private let bundle: Bundle
    private let defaults: UserDefaults

    init(libraryId: UUID, modelContext: ModelContext, bundle: Bundle = .main, defaults: UserDefaults = .standard) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        self.bundle = bundle
        self.defaults = defaults

        let excluded = Set(TemplateDAL.starterPackIds + [Self.commonPackId])
        self.choices = TemplatePackDAL.availablePacks(bundle: bundle)
            .filter { !excluded.contains($0.packId) }
            .map { Choice(pack: $0, isSelected: false) }
    }

    var selectedCount: Int { choices.filter(\.isSelected).count }
    var needsBulkConfirmation: Bool { selectedCount > Self.bulkAddThreshold }

    func toggle(_ packId: String) {
        guard let index = choices.firstIndex(where: { $0.id == packId }) else { return }
        choices[index].isSelected.toggle()
    }

    /// "Skip" — add nothing, never show onboarding again.
    func skip() {
        TemplateOnboardingStore.markCompleted(in: defaults)
    }

    /// Add the selected packs (plus Common / KM Essentials when at least one is chosen), then
    /// mark onboarding complete. Idempotent add: `TemplatePackDAL` refuses a duplicate.
    func commit() {
        let selected = choices.filter(\.isSelected).map(\.pack)
        if !selected.isEmpty {
            TemplatePackDAL.addPack(id: Self.commonPackId, libraryId: libraryId, bundle: bundle, in: modelContext)
            for pack in selected {
                TemplatePackDAL.addPack(pack, libraryId: libraryId, in: modelContext)
            }
        }
        TemplateOnboardingStore.markCompleted(in: defaults)
    }
}
