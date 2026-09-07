// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplatePackPreviewView.swift
//  Kontinuum
//

import SwiftUI
import MarkdownG9

/// Preview of a bundled Template Pack before adding it — every template's field list and its
/// body scaffold rendered as it will appear, plus any pack-level scope note. Per
/// NoteBytez20260824v1-Templates.md Phase 4.5 / R4.
struct TemplatePackPreviewView: View {

    let pack: TemplatePackDefinition
    let state: TemplateGalleryViewModel.PackState
    @State var viewModel: TemplateGalleryViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Text(pack.summary)
                    .font(.subheadline)
                if let note = pack.note {
                    Label(note, systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                if !pack.roleAliases.isEmpty {
                    Text("For: " + pack.roleAliases.joined(separator: ", "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(pack.templates) { template in
                Section(template.name) {
                    if !template.fields.isEmpty {
                        ForEach(template.fields, id: \.name) { field in
                            HStack {
                                Text(field.name)
                                Spacer()
                                Text(field.valueType.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    if let body = template.bodyTemplate, !body.isEmpty {
                        Text(MDProcessor.process(body))
                            .font(.callout)
                            .textSelection(.enabled)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(pack.displayName)
        .noteBytezInlineNavigationTitle()
        .safeAreaInset(edge: .bottom) {
            actionButton
                .padding()
                .background(.bar)
        }
    }

    @ViewBuilder private var actionButton: some View {
        switch state {
        case .notAdded:
            PrimaryButton(title: "Add to Library") {
                viewModel.add(pack)
                dismiss()
            }
        case .updateAvailable:
            PrimaryButton(title: "Update Available — Apply") {
                viewModel.applyUpdate(pack)
                dismiss()
            }
        case .added:
            Label("Added to this library", systemImage: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .frame(maxWidth: .infinity)
        }
    }
}
