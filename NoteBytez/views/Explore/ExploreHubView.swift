// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ExploreHubView.swift
//  NoteBytez
//

import SwiftUI

/// S27 — Explore Hub. iPhone's 4th tab: a plain list pushing to every destination that has no
/// dedicated tab of its own on iPhone (Decision 2) — Graph, Insights, Tasks, Saved Views,
/// Canvas, Tags — plus a Command Palette row, since iPhone has no hardware ⌘P.
struct ExploreHubView: View {

    let library: Library

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(AppDestination.exploreHubDestinations) { destination in
                NavigationLink {
                    destinationView(for: destination)
                } label: {
                    Label(destination.rawValue, systemImage: destination.systemImage)
                }
            }
            Button {
                NotificationCenter.default.post(name: .noteBytezOpenCommandPalette, object: nil)
            } label: {
                Label("Command Palette", systemImage: "command")
            }
        }
        .navigationTitle("Explore")
        .noteBytezInlineNavigationTitle()
    }

    @ViewBuilder
    private func destinationView(for destination: AppDestination) -> some View {
        if let libraryId = library.libraryId {
            switch destination {
            case .graph:
                TodayGraphView(libraryId: libraryId)
            case .insights:
                GraphInsightsView(viewModel: GraphInsightsViewModel(libraryId: libraryId, modelContext: modelContext))
            case .tasks:
                TaskDashboardView(viewModel: TaskDashboardViewModel(libraryId: libraryId, modelContext: modelContext))
            case .savedViews:
                SavedViewsListView(viewModel: SavedViewViewModel(libraryId: libraryId, modelContext: modelContext))
            case .canvas:
                CanvasBoardListView(viewModel: CanvasViewModel(libraryId: libraryId, modelContext: modelContext))
            case .tags:
                TagBrowserView(viewModel: TagViewModel(libraryId: libraryId, modelContext: modelContext))
            default:
                EmptyView()
            }
        } else {
            Text(destination.rawValue)
        }
    }

}
