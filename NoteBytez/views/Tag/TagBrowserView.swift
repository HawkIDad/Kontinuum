// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagBrowserView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// S13 — Tag Browser. Alphabetical list of every tag in the library with its note count;
/// tapping a tag jumps to its tagged notes (a stand-in for S7 Search Results' tag-filter
/// scope until Phase 9 builds real Search — see `TaggedDocumentsView`).
struct TagBrowserView: View {

    var viewModel: TagViewModel

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            if viewModel.tagSummaries.isEmpty {
                ContentUnavailableView(
                    "No Tags Yet",
                    systemImage: "tag",
                    description: Text("Type # in any note to create one.")
                )
            } else {
                ForEach(viewModel.tagSummaries) { summary in
                    NavigationLink {
                        TaggedDocumentsView(tag: summary.tag)
                    } label: {
                        TagListRow(name: summary.tag.name ?? "", noteCount: summary.noteCount)
                    }
                }
            }
        }
        .navigationTitle("Tags")
        .noteBytezInlineNavigationTitle()
        .onAppear {
            viewModel.load()
        }
    }

}
