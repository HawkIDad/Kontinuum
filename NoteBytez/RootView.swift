// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  RootView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// App entry point: shows S1 (Library Creation/Selection) until a library is selected,
/// then hands off to the main navigation shell.
struct RootView: View {

    @Environment(\.modelContext) private var modelContext
    @State private var libraryViewModel: LibraryViewModel?
    @State private var didFinishTemplateOnboarding = false

    var body: some View {
        // App Store provenance + subscription gate (NoteBytez20260907v1-Security.md). Renders
        // the app below only when entitled; otherwise a paywall / blocked screen.
        EntitlementGateContainer(viewModel: .makeDefault()) {
            libraryContent
        }
    }

    private var libraryContent: some View {
        Group {
            if let libraryViewModel {
                if let selectedLibrary = libraryViewModel.selectedLibrary {
                    if shouldShowTemplateOnboarding, let libraryId = selectedLibrary.libraryId {
                        RoleOnboardingView(
                            viewModel: TemplateOnboardingViewModel(libraryId: libraryId, modelContext: modelContext),
                            onFinished: { didFinishTemplateOnboarding = true }
                        )
                    } else {
                        ContentView(library: selectedLibrary)
                    }
                } else {
                    LibrarySelectionView(viewModel: libraryViewModel)
                }
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if self.libraryViewModel == nil {
                self.libraryViewModel = LibraryViewModel(modelContext: self.modelContext)
                BlockDAL.backfillHeadingPathsIfNeeded(in: self.modelContext)
            }
        }
    }

    private var shouldShowTemplateOnboarding: Bool {
        !didFinishTemplateOnboarding && !TemplateOnboardingStore.hasCompleted()
    }

}
