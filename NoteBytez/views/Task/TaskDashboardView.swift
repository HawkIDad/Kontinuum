// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskDashboardView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// S19 — Task Dashboard. Cross-note task list, status/date filter chips, and a tag filter
/// field, per NoteBytez-R1-Implementation.md Phase 6.
struct TaskDashboardView: View {

    @Bindable var viewModel: TaskDashboardViewModel

    @Environment(\.modelContext) private var modelContext
    @State private var documentTarget: Document?
    @State private var savedViewViewModel: SavedViewViewModel?
    @State private var isPresentingSaveAlert = false
    @State private var newSavedViewName = ""
    @State private var savedViewTarget: SavedView?

    var body: some View {
        VStack(spacing: 0) {
            FilterChipRow(scopes: TaskDashboardViewModel.StatusFilter.allCases, selected: $viewModel.statusFilter)
                .padding(.horizontal)
                .padding(.top, 8)

            FilterChipRow(scopes: TaskDashboardViewModel.DateFilter.allCases, selected: $viewModel.dateFilter)
                .padding(.horizontal)
                .padding(.top, 8)

            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
                TextField("Filter by tag", text: $viewModel.tagFilter)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.noteBytezSecondarySurface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.top, 8)

            if let savedViewViewModel, !savedViewViewModel.savedTaskViews.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(savedViewViewModel.savedTaskViews) { savedView in
                            SavedViewChip(savedView: savedView) { savedViewTarget = savedView }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }

            Divider()
                .padding(.top, 8)

            if viewModel.filteredTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checklist",
                    description: Text("Nothing matches the current filters.")
                )
            } else {
                List(viewModel.filteredTasks) { dashboardTask in
                    Button {
                        documentTarget = dashboardTask.task.documentId.flatMap { Document.fetch(syncId: $0, in: modelContext) }
                    } label: {
                        TaskDashboardRow(dashboardTask: dashboardTask) {
                            viewModel.toggle(dashboardTask)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Tasks")
        .noteBytezInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newSavedViewName = "\(viewModel.statusFilter.rawValue) Tasks"
                    isPresentingSaveAlert = true
                } label: {
                    Image(systemName: "pin")
                }
                .accessibilityLabel("Save These Filters")
            }
        }
        .onAppear {
            if savedViewViewModel == nil {
                savedViewViewModel = SavedViewViewModel(libraryId: viewModel.libraryId, modelContext: modelContext)
            }
        }
        .alert("Save Task View", isPresented: $isPresentingSaveAlert) {
            TextField("Name", text: $newSavedViewName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = newSavedViewName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                savedViewViewModel?.saveTaskQuery(name: trimmed, statusFilter: viewModel.statusFilter, dateFilter: viewModel.dateFilter, tagFilter: viewModel.tagFilter)
            }
        }
        .navigationDestination(item: $documentTarget) { document in
            DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
        }
        .navigationDestination(item: $savedViewTarget) { savedView in
            if let savedViewViewModel {
                SavedViewResultsView(savedView: savedView, viewModel: savedViewViewModel)
            }
        }
    }

}
