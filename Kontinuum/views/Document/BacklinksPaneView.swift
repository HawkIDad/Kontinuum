// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BacklinksPaneView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData

/// S5 — Backlinks Pane. Presented as a sheet for now; docking it alongside S4 on Mac/iPad
/// is cross-platform layout polish that belongs in Phase 14, not here.
struct BacklinksPaneView: View {

    var viewModel: BacklinksViewModel

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            Section("Linked Mentions") {
                if viewModel.backlinks.isEmpty {
                    Text("No backlinks yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.backlinks) { match in
                        NavigationLink {
                            DocumentView(viewModel: DocumentViewModel(document: match.sourceDocument, modelContext: modelContext))
                        } label: {
                            BacklinkRow(match: match)
                        }
                    }
                }
            }

            Section("Unlinked Mentions") {
                if viewModel.unlinkedMentions.isEmpty {
                    Text("No unlinked mentions.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.unlinkedMentions) { match in
                        NavigationLink {
                            DocumentView(viewModel: DocumentViewModel(document: match.sourceDocument, modelContext: modelContext))
                        } label: {
                            UnlinkedMentionRow(match: match)
                        }
                    }
                }
            }

            if !viewModel.blockBacklinks.isEmpty {
                Section("Block References") {
                    ForEach(viewModel.blockBacklinks) { group in
                        Text("((\(group.anchor)))")
                            .font(.callout.monospaced())
                            .foregroundStyle(.secondary)
                        ForEach(group.matches) { match in
                            NavigationLink {
                                DocumentView(viewModel: DocumentViewModel(document: match.sourceDocument, modelContext: modelContext))
                            } label: {
                                BacklinkRow(match: match)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Backlinks")
        .noteBytezInlineNavigationTitle()
    }

}
