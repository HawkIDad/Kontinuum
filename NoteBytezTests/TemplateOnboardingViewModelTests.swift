// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateOnboardingViewModelTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

@MainActor
struct TemplateOnboardingViewModelTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Notebook.self, DocumentNotebook.self,
            Property.self, DocumentProperty.self, TemplateGroup.self, NoteTemplate.self,
            NotebookTemplateGroup.self, JournalTemplateGroup.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func freshDefaults() -> UserDefaults {
        let suite = "onboarding.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    @Test func choicesExcludeTheCreativeStartersAndTheCommonPack() throws {
        let viewModel = TemplateOnboardingViewModel(libraryId: UUID(), modelContext: try makeContext(), defaults: freshDefaults())
        let ids = Set(viewModel.choices.map(\.id))
        #expect(!ids.contains("common-km-essentials"))
        #expect(ids.isDisjoint(with: Set(TemplateDAL.starterPackIds)))
        #expect(viewModel.choices.count == 16, "20 packs − 3 starters − Common")
    }

    @Test func skipAddsNothingAndMarksOnboardingComplete() throws {
        let context = try makeContext()
        let defaults = freshDefaults()
        let libraryId = UUID()
        let viewModel = TemplateOnboardingViewModel(libraryId: libraryId, modelContext: context, defaults: defaults)

        viewModel.skip()

        #expect(TemplateOnboardingStore.hasCompleted(in: defaults))
        #expect(TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context).isEmpty)
    }

    @Test func committingSelectionsAddsThemPlusTheCommonPack() throws {
        let context = try makeContext()
        let defaults = freshDefaults()
        let libraryId = UUID()
        let viewModel = TemplateOnboardingViewModel(libraryId: libraryId, modelContext: context, defaults: defaults)

        viewModel.toggle("software-engineering")
        viewModel.toggle("project-management")
        viewModel.commit()

        let names = Set(TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context).compactMap(\.name))
        #expect(names == ["Common / KM Essentials", "Software Engineering", "Project Management"])
        #expect(TemplateOnboardingStore.hasCompleted(in: defaults))
    }

    @Test func bulkConfirmationTriggersAboveFourSelections() throws {
        let viewModel = TemplateOnboardingViewModel(libraryId: UUID(), modelContext: try makeContext(), defaults: freshDefaults())
        for id in ["software-engineering", "project-management", "sales", "marketing"] { viewModel.toggle(id) }
        #expect(!viewModel.needsBulkConfirmation)
        viewModel.toggle("customer-success")
        #expect(viewModel.needsBulkConfirmation)
    }

    @Test func committingNothingStillCompletesOnboardingWithoutAddingCommon() throws {
        let context = try makeContext()
        let defaults = freshDefaults()
        let libraryId = UUID()
        let viewModel = TemplateOnboardingViewModel(libraryId: libraryId, modelContext: context, defaults: defaults)

        viewModel.commit()

        #expect(TemplateDAL.fetchActiveGroups(libraryId: libraryId, in: context).isEmpty)
        #expect(TemplateOnboardingStore.hasCompleted(in: defaults))
    }
}
