// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateGroupListView.swift
//  NoteBytez
//

import SwiftUI

/// S18 Manager, level 1 — every `TemplateGroup` in the library. Reached from Settings.
struct TemplateGroupListView: View {

    var viewModel: TemplateViewModel

    @State private var newGroupName = ""

    var body: some View {
        List {
            Section {
                if viewModel.groups.isEmpty {
                    ContentUnavailableView(
                        "No Template Groups Yet",
                        systemImage: "doc.badge.plus",
                        description: Text("Add a group below to start building reusable templates.")
                    )
                } else {
                    ForEach(viewModel.groups) { group in
                        NavigationLink(group.name ?? "Untitled Group") {
                            NoteTemplateListView(viewModel: viewModel, group: group)
                        }
                    }
                    .onDelete { offsets in
                        for index in offsets { viewModel.deleteGroup(viewModel.groups[index]) }
                    }
                }
            }

            Section("New Group") {
                HStack {
                    TextField("Group name", text: $newGroupName)
                    Button("Add") {
                        viewModel.createGroup(name: newGroupName.trimmingCharacters(in: .whitespacesAndNewlines))
                        newGroupName = ""
                    }
                    .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle("Templates")
        .noteBytezInlineNavigationTitle()
    }

}
