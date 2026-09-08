// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NoteTemplateListView.swift
//  Kontinuum
//

import SwiftUI

/// S18 Manager, level 2 — every `NoteTemplate` in one `TemplateGroup`.
struct NoteTemplateListView: View {

    var viewModel: TemplateViewModel
    let group: TemplateGroup

    @State private var templates: [NoteTemplate] = []
    @State private var newTemplateName = ""

    var body: some View {
        List {
            Section {
                if templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates Yet",
                        systemImage: "doc.badge.plus",
                        description: Text("Add a template below.")
                    )
                } else {
                    ForEach(templates) { template in
                        NavigationLink(template.name ?? "Untitled Template") {
                            NoteTemplateFieldsView(viewModel: viewModel, template: template)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { viewModel.deleteTemplate(templates[index]) }
                        reload()
                    }
                }
            }

            Section("New Template") {
                HStack {
                    TextField("Template name", text: $newTemplateName)
                    Button("Add") {
                        viewModel.createTemplate(name: newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines), in: group)
                        newTemplateName = ""
                        reload()
                    }
                    .disabled(newTemplateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle(group.name ?? "Group")
        .noteBytezInlineNavigationTitle()
        .onAppear { reload() }
    }

    private func reload() {
        templates = viewModel.templates(in: group)
    }

}
