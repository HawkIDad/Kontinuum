// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  BackupSnapshotRow.swift
//  NoteBytez
//

import SwiftUI

/// Timestamp + cause label + restore action, per docs/styleGuide.md.
struct BackupSnapshotRow: View {

    let snapshot: BackupSnapshot
    let onRestore: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.createdOn, format: .dateTime.month().day().year().hour().minute())
                Text(snapshot.cause == .automatic ? "Automatic" : "Manual")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)

            Spacer()

            SecondaryButton(title: "Restore", action: onRestore)
        }
    }

}
