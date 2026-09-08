// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BackupRestoreView.swift
//  Kontinuum
//

import SwiftUI

/// S12 — Backup & Restore.
struct BackupRestoreView: View {

    var viewModel: BackupViewModel
    @State private var snapshotPendingRestore: BackupSnapshot?

    var body: some View {
        List {
            if viewModel.snapshots.isEmpty {
                ContentUnavailableView(
                    "No Backups Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Snapshots are created automatically before risky operations, or manually below.")
                )
            } else {
                ForEach(viewModel.snapshots) { snapshot in
                    BackupSnapshotRow(snapshot: snapshot) {
                        snapshotPendingRestore = snapshot
                    }
                }
            }
        }
        .navigationTitle("Backups")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Create Backup") {
                    viewModel.createManualSnapshot()
                }
            }
        }
        .confirmationDialog(
            "Restore this backup?",
            isPresented: Binding(
                get: { snapshotPendingRestore != nil },
                set: { isPresented in if !isPresented { snapshotPendingRestore = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Restore", role: .destructive) {
                if let snapshot = snapshotPendingRestore {
                    viewModel.restore(snapshot)
                }
                snapshotPendingRestore = nil
            }
            Button("Cancel", role: .cancel) {
                snapshotPendingRestore = nil
            }
        } message: {
            Text("This replaces current data with the snapshot's contents.")
        }
    }

}
