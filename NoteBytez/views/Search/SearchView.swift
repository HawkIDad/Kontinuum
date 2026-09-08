// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SearchView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// S7 — Search Results. Persistent search field, content/tag/path scope chips, result rows
/// with a matched-text snippet.
struct SearchView: View {

    @Bindable var viewModel: SearchViewModel

    @Environment(\.modelContext) private var modelContext
    @State private var savedViewViewModel: SavedViewViewModel?
    @State private var isPresentingSaveAlert = false
    @State private var newSavedViewName = ""
    @State private var savedViewTarget: SavedView?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(viewModel.isAdvancedMode ? "#tag AND \"phrase\" NOT /regex/" : "Search", text: $viewModel.query)
                    .textFieldStyle(.plain)
                    .onChange(of: viewModel.query) { _, _ in viewModel.search() }

                Button {
                    viewModel.isAdvancedMode.toggle()
                    viewModel.search()
                } label: {
                    Image(systemName: "function")
                }
                .buttonStyle(.plain)
                .foregroundStyle(viewModel.isAdvancedMode ? Color.accentColor : .secondary)
                .accessibilityLabel(viewModel.isAdvancedMode ? "Advanced Search: On" : "Advanced Search: Off")
            }
            .padding(10)
            .background(Color.noteBytezSecondarySurface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding([.horizontal, .top])

            if viewModel.isAdvancedMode {
                Text("AND / OR / NOT · \"exact phrase\" · /regex/ · #tag — combine freely, e.g. #character AND #act2 NOT #resolved")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            FilterChipRow(scopes: SearchViewModel.Scope.allCases, selected: $viewModel.scope)
                .padding(.horizontal)
                .padding(.top, 8)
                .onChange(of: viewModel.scope) { _, _ in viewModel.search() }

            if let savedViewViewModel, !savedViewViewModel.savedSearchViews.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(savedViewViewModel.savedSearchViews) { savedView in
                            SavedViewChip(savedView: savedView) { savedViewTarget = savedView }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top, 8)
            }

            Divider()
                .padding(.top, 8)

            if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView.search
            } else if viewModel.results.isEmpty {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No notes match \"\(viewModel.query)\" in \(viewModel.scope.rawValue).")
                )
            } else {
                List(viewModel.results) { result in
                    NavigationLink {
                        DocumentView(viewModel: DocumentViewModel(document: result.document, modelContext: modelContext))
                    } label: {
                        SearchResultRow(title: result.document.title ?? "", snippet: result.snippet)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Search")
        .noteBytezInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newSavedViewName = viewModel.query
                    isPresentingSaveAlert = true
                } label: {
                    Image(systemName: "pin")
                }
                .disabled(viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel("Save This Search")
            }
        }
        .onAppear {
            if savedViewViewModel == nil {
                savedViewViewModel = SavedViewViewModel(libraryId: viewModel.libraryId, modelContext: modelContext)
            }
        }
        .alert("Save Search", isPresented: $isPresentingSaveAlert) {
            TextField("Name", text: $newSavedViewName)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = newSavedViewName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                savedViewViewModel?.saveSearch(name: trimmed, query: viewModel.query, scope: viewModel.scope, isAdvancedMode: viewModel.isAdvancedMode)
            }
        }
        .navigationDestination(item: $savedViewTarget) { savedView in
            if let savedViewViewModel {
                SavedViewResultsView(savedView: savedView, viewModel: savedViewViewModel)
            }
        }
    }

}
