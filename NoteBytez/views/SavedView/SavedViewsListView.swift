// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedViewsListView.swift
//  Kontinuum
//

import SwiftUI

/// S21 — Saved Views. Every pinned search/task query, reorderable and deletable.
struct SavedViewsListView: View {

    var viewModel: SavedViewViewModel

    var body: some View {
        List {
            if viewModel.savedViews.isEmpty {
                ContentUnavailableView(
                    "No Saved Views",
                    systemImage: "pin",
                    description: Text("Save a search or task filter to pin it here.")
                )
            } else {
                ForEach(viewModel.savedViews) { savedView in
                    NavigationLink {
                        SavedViewResultsView(savedView: savedView, viewModel: viewModel)
                    } label: {
                        Label(savedView.name ?? "Untitled", systemImage: icon(for: savedView.savedQueryType))
                    }
                }
                .onDelete { offsets in
                    for index in offsets { viewModel.delete(viewModel.savedViews[index]) }
                }
                .onMove { source, destination in
                    var reordered = viewModel.savedViews
                    reordered.move(fromOffsets: source, toOffset: destination)
                    viewModel.reorder(reordered)
                }
            }
        }
        .navigationTitle("Saved Views")
        .noteBytezInlineNavigationTitle()
        .toolbar {
            // `EditButton()` is unavailable on macOS — unneeded there anyway, since a macOS
            // `List` already supports `.onMove` drag-to-reorder and `.onDelete` (via the delete
            // key / right-click) directly, with no edit-mode toggle to surface them.
#if os(iOS)
            if !viewModel.savedViews.isEmpty {
                EditButton()
            }
#endif
        }
    }

    private func icon(for queryType: SavedViewQueryType?) -> String {
        switch queryType {
        case .task: return "checklist"
        case .graph: return "circle.grid.cross"
        case .search, nil: return "magnifyingglass"
        }
    }

}
