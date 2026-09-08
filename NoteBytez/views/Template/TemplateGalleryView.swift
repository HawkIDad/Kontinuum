// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateGalleryView.swift
//  Kontinuum
//

import SwiftUI

/// S28 — Template Gallery. Browsable bundled Template Packs grouped by category; tap a pack to
/// preview it, then add it to the library as editable template groups. Per
/// NoteBytez20260824v1-Templates.md Phase 4. Reached from Settings → Template Gallery and from
/// first-run onboarding.
struct TemplateGalleryView: View {

    @State var viewModel: TemplateGalleryViewModel
    @State private var searchText = ""

    private var visibleCategories: [String] {
        let matched = Set(viewModel.filteredRows(matching: searchText).map(\.pack.category))
        return viewModel.categories.filter { matched.contains($0) }
    }

    private func rows(in category: String) -> [TemplateGalleryViewModel.Row] {
        let matchedIds = Set(viewModel.filteredRows(matching: searchText).map(\.id))
        return viewModel.rows(in: category).filter { matchedIds.contains($0.id) }
    }

    var body: some View {
        List {
            ForEach(visibleCategories, id: \.self) { category in
                Section(category) {
                    ForEach(rows(in: category)) { row in
                        NavigationLink {
                            TemplatePackPreviewView(pack: row.pack, state: row.state, viewModel: viewModel)
                        } label: {
                            TemplatePackRow(row: row)
                        }
                    }
                }
            }
        }
        .navigationTitle("Template Gallery")
        .noteBytezInlineNavigationTitle()
        .searchable(text: $searchText, prompt: "Search packs or job titles")
        .overlay {
            if visibleCategories.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
        .onAppear { viewModel.refresh() }
    }
}

/// One pack in the gallery list — name, one-line summary, and its added/updatable state.
struct TemplatePackRow: View {

    let row: TemplateGalleryViewModel.Row

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(row.pack.displayName)
                    .font(.body.weight(.medium))
                Spacer()
                stateBadge
            }
            Text(row.pack.summary)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var stateBadge: some View {
        switch row.state {
        case .notAdded:
            EmptyView()
        case .added:
            Label("Added", systemImage: "checkmark.circle.fill")
                .labelStyle(.iconOnly)
                .foregroundStyle(.green)
                .accessibilityLabel("Added")
        case .updateAvailable:
            Text("Update")
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.accentColor.opacity(0.15))
                .clipShape(Capsule())
                .foregroundStyle(Color.accentColor)
                .accessibilityLabel("Update available")
        }
    }
}
