// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncStatusView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// S9 — Sync Status / Log. Current status headline, last-synced timestamp (always visible,
/// even offline), a dismissible inline error banner when the last sync attempt failed, the
/// chronological event log, and an always-available manual "Sync Now" trigger.
///
/// Presented as a sheet from S3/S4's `SyncStatusGlyph` on every platform — the wireframe calls
/// for a Mac/iPad popover instead, but this codebase already established the same sheet-based
/// deviation for S5/S8/S13 (see Phase 4/11's notes); cross-platform presentation polish belongs
/// in Phase 15, not here.
struct SyncStatusView: View {

    var viewModel: SyncStatusViewModel
    var conflictStore: ConflictStore = .shared

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    SyncStatusGlyph(viewModel: viewModel)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.statusHeadline)
                            .font(.headline)
                        Text(viewModel.lastSyncedText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if viewModel.isSharedLibrary {
                    Label("This library is shared", systemImage: "person.2.fill")
                        .foregroundStyle(.secondary)
                }
            }

            // SF 7 — a manual resolution stays undoable for `ConflictStore.undoWindow`.
            if let undo = conflictStore.pendingUndo {
                Section {
                    UndoToast(title: undo.conflict.title) {
                        Task { await SyncEngine.shared.undoResolution(undo, in: modelContext) }
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            if conflictStore.conflicts.isEmpty && conflictStore.recentlyResolved.isEmpty {
                // SF 4 — the calm all-clear state once every conflict has been resolved (and
                // the design system's prescribed S9 Empty state).
                Section {
                    Label("No conflicts — you're all synced", systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("sync.noConflicts")
                }
            } else {
                Section("Needs Your Attention") {
                    ForEach(conflictStore.conflicts) { conflict in
                        NavigationLink {
                            ConflictResolutionView(
                                viewModel: ConflictResolutionViewModel(conflict: conflict, modelContext: modelContext)
                            )
                        } label: {
                            Label("Conflict — \"\(conflict.title)\"", systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                        }
                    }
                    // SF 4 — a just-resolved conflict lingers here as "Resolved ✓" for
                    // `ConflictStore.acknowledgementDuration` before its row animates out.
                    ForEach(Array(conflictStore.recentlyResolved.values)) { ack in
                        Label("Resolved — \(ack.summary)", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .accessibilityIdentifier("sync.resolvedAck")
                            .transition(.opacity)
                    }
                }
            }

            if let error = viewModel.dismissibleError {
                Section {
                    SyncErrorBanner(
                        entry: error,
                        onRetry: { viewModel.syncNow() },
                        onDismiss: { viewModel.dismissError() }
                    )
                }
            }

            Section("Recent Activity") {
                if viewModel.logEntries.isEmpty {
                    ContentUnavailableView(
                        "No Sync Activity Yet",
                        systemImage: "arrow.triangle.2.circlepath",
                        description: Text("Sync events will appear here.")
                    )
                } else {
                    ForEach(viewModel.logEntries) { entry in
                        SyncLogRow(entry: entry)
                    }
                }
            }

            Section {
                Button("Sync Now") {
                    viewModel.syncNow()
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .padding()
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Sync Status")
        .noteBytezInlineNavigationTitle()
        .animation(.default, value: conflictStore.conflicts.count)
        .animation(.default, value: conflictStore.recentlyResolved.count)
        .animation(.default, value: conflictStore.pendingUndo?.id)
    }

}

/// State convention #4 — "inline, dismissible, with a retry action... never a blocking alert."
private struct SyncErrorBanner: View {

    let entry: SyncLogEntry
    let onRetry: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 6) {
                Text(entry.message)
                    .font(.callout)

                HStack {
                    Button("Retry", action: onRetry)
                        .font(.callout.weight(.semibold))
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Dismiss")
                }
            }
        }
        .padding(.vertical, 4)
    }

}
