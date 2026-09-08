// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  RoleOnboardingView.swift
//  Kontinuum
//

import SwiftUI

/// First-run role picker — shown once by `RootView` after the first library exists. "What do
/// you use Kontinuum for?"; selected packs (plus Common / KM Essentials) are added, or Skip.
/// Per NoteBytez20260824v1-Templates.md Phase 5.
struct RoleOnboardingView: View {

    @State var viewModel: TemplateOnboardingViewModel
    let onFinished: () -> Void

    @State private var isConfirmingBulkAdd = false

    private var groupedByCategory: [(category: String, choices: [TemplateOnboardingViewModel.Choice])] {
        let order = TemplateGalleryViewModel.categoryOrder
        let grouped = Dictionary(grouping: viewModel.choices, by: { $0.pack.category })
        return grouped.keys
            .sorted { (order.firstIndex(of: $0) ?? .max, $0) < (order.firstIndex(of: $1) ?? .max, $1) }
            .map { ($0, grouped[$0] ?? []) }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Pick the kinds of work you do and NoteBytez will add matching note templates. You can change these any time in Settings → Template Gallery.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(groupedByCategory, id: \.category) { section in
                    Section(section.category) {
                        ForEach(section.choices) { choice in
                            Button {
                                viewModel.toggle(choice.id)
                            } label: {
                                HStack(alignment: .firstTextBaseline) {
                                    Image(systemName: choice.isSelected ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(choice.isSelected ? Color.accentColor : .secondary)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(choice.pack.displayName)
                                        Text(choice.pack.summary)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(choice.isSelected ? .isSelected : [])
                        }
                    }
                }
            }
            .navigationTitle("What do you use NoteBytez for?")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        viewModel.skip()
                        onFinished()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if viewModel.needsBulkConfirmation {
                            isConfirmingBulkAdd = true
                        } else {
                            finish()
                        }
                    }
                    .disabled(viewModel.selectedCount == 0)
                }
            }
            .confirmationDialog(
                "Add \(viewModel.selectedCount) template groups to your library?",
                isPresented: $isConfirmingBulkAdd, titleVisibility: .visible
            ) {
                Button("Add \(viewModel.selectedCount) groups") { finish() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func finish() {
        viewModel.commit()
        onFinished()
    }
}
