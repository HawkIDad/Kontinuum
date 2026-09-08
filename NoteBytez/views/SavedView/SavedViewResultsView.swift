// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SavedViewResultsView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// Live results for one pinned Saved View — reached from S21's list or a `SavedViewChip`.
/// Re-evaluates fresh on every appearance, never a frozen snapshot from when it was saved.
struct SavedViewResultsView: View {

    let savedView: SavedView
    var viewModel: SavedViewViewModel

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Group {
            switch savedView.savedQueryType {
            case .search:
                searchResultsList
            case .task:
                taskResultsList
            case .graph:
                graphResultsView
            case nil:
                EmptyView()
            }
        }
        .navigationTitle(savedView.name ?? "Saved View")
        .noteBytezInlineNavigationTitle()
    }

    @ViewBuilder
    private var searchResultsList: some View {
        let results = viewModel.searchResults(for: savedView)
        if results.isEmpty {
            ContentUnavailableView("No Results", systemImage: "magnifyingglass")
        } else {
            List(results) { result in
                NavigationLink {
                    DocumentView(viewModel: DocumentViewModel(document: result.document, modelContext: modelContext))
                } label: {
                    SearchResultRow(title: result.document.title ?? "", snippet: result.snippet)
                }
            }
            .listStyle(.plain)
        }
    }

    /// Opens straight into S8 Force mode with the saved filter applied (A6) — a saved graph
    /// view isn't a list of results like search/task, it's a live re-entry into the graph
    /// itself, re-evaluated fresh (same "never a frozen snapshot" rule as the other two).
    @ViewBuilder
    private var graphResultsView: some View {
        if let definition = savedView.graphDefinition,
           let focusDocument = Document.fetch(syncId: definition.focusDocumentId, in: modelContext) {
            GraphView(viewModel: GraphViewModel(
                document: focusDocument,
                modelContext: modelContext,
                initialMode: .force,
                initialFilter: definition.filter
            ))
        } else {
            ContentUnavailableView("Note Not Found", systemImage: "circle.grid.cross")
        }
    }

    @ViewBuilder
    private var taskResultsList: some View {
        let tasks = viewModel.taskResults(for: savedView)
        if tasks.isEmpty {
            ContentUnavailableView("No Tasks", systemImage: "checklist")
        } else {
            List(tasks) { dashboardTask in
                TaskDashboardRow(dashboardTask: dashboardTask) {
                    TaskDAL.toggle(dashboardTask.task, in: modelContext)
                }
            }
            .listStyle(.plain)
        }
    }

}
