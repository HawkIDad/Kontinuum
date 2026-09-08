// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictVersionCard.swift
//  Kontinuum
//

import SwiftUI

/// S10's Keep-All-Versions strategy — one card per revision: label + timestamp + snippet +
/// per-version keep action. Never anonymous, per the wireframe's own note.
struct ConflictVersionCard: View {

    let revision: ConflictRevision
    let onKeep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(revision.label)
                        .font(.headline)
                    Spacer()
                    if let timestamp = revision.timestamp {
                        Text(timestamp, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(revision.snippet.isEmpty ? "(empty)" : revision.snippet)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            .accessibilityElement(children: .combine)

            Button("Keep This Version", action: onKeep)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.noteBytezSecondarySurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

}
