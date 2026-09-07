// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictResolutionView.swift
//  Kontinuum
//

import SwiftUI

/// S10 — Conflict Resolution. Reached from S9 for a queued conflict (Keep-All-Versions always
/// queues; Diff-Merge queues only when there's text to diff — anything else auto-resolves
/// before ever reaching here, see `SyncEngine.handleDetectedConflict`).
///
/// The wireframe's third sub-UI — a Last-Write-Wins banner "atop the merged note" — is instead
/// embedded directly in S4 (`ConflictBanner`, wired in `DocumentView`), since that strategy
/// never queues a conflict for S10 to show in the first place; duplicating it here would be a
/// dead end nobody reaches through the normal flow.
struct ConflictResolutionView: View {

    var viewModel: ConflictResolutionViewModel
    var onResolved: () -> Void = {}

    private var showsDiffMerge: Bool {
        viewModel.strategy == .diffMerge && viewModel.conflict.hasDiffableContent
    }

    var body: some View {
        Group {
            if showsDiffMerge {
                diffMergeContent
            } else {
                keepAllVersionsContent
            }
        }
        .navigationTitle("Conflict: \"\(viewModel.conflict.title)\"")
        .noteBytezInlineNavigationTitle()
        .disabled(viewModel.isResolving)
        .overlay {
            if viewModel.isResolving {
                ProgressView()
            }
        }
    }

    private var keepAllVersionsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.conflict.revisions) { revision in
                    ConflictVersionCard(revision: revision) {
                        Task {
                            await viewModel.resolve(choice: revision.kind == .client ? .keepClient : .keepServer)
                            onResolved()
                        }
                    }
                }

                if viewModel.conflict.recordType == Document.ckRecordType {
                    Button("Keep Both Versions") {
                        Task {
                            await viewModel.resolve(choice: .keepBoth)
                            onResolved()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
        }
    }

    private var diffMergeContent: some View {
        VStack(spacing: 0) {
            DiffMergeView(hunks: viewModel.diffHunks, acceptedHunkIDs: viewModel.acceptedHunkIDs) { hunk in
                viewModel.toggleHunk(hunk)
            }
            Divider()
            Button("Save Merged Note") {
                Task {
                    await viewModel.confirmMerge()
                    onResolved()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }

}
