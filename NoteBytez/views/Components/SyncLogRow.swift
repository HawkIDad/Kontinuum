// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SyncLogRow.swift
//  NoteBytez
//

import SwiftUI

/// One row of S9's chronological event log: a short timestamp + event description, orange
/// (with a warning glyph, per the design system's "never color alone" rule) when the entry is
/// an error or conflict — matches the `05-Wireframes.md` S9 log format (`08:14  Synced — …`).
struct SyncLogRow: View {

    let entry: SyncLogEntry

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(entry.timestamp, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()

            if entry.isError {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .accessibilityLabel("Error")
            }

            Text(entry.message)
                .font(.callout)
                .foregroundStyle(entry.isError ? .orange : .primary)
        }
        .accessibilityElement(children: .combine)
    }

}
