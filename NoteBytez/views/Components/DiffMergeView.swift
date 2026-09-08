// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  DiffMergeView.swift
//  NoteBytez
//

import SwiftUI

/// S10's Diff-Merge strategy — two-column old|new per changed hunk, each with an accept
/// toggle; unchanged hunks render as plain context. "Old" is the synced (server) revision,
/// "new" is this device's edit, matching `MarkdownDiffMerge`'s own old/new framing.
struct DiffMergeView: View {

    let hunks: [DiffHunk]
    let acceptedHunkIDs: Set<UUID>
    let onToggle: (DiffHunk) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(hunks) { hunk in
                    switch hunk.kind {
                    case .unchanged where !hunk.unchangedLines.isEmpty:
                        Text(hunk.unchangedLines.joined(separator: "\n"))
                            .font(.body.monospaced())
                            .foregroundStyle(.secondary)
                    case .unchanged:
                        EmptyView()
                    case .changed:
                        changedHunkRow(hunk)
                    }
                }
            }
            .padding()
        }
    }

    private func changedHunkRow(_ hunk: DiffHunk) -> some View {
        let isAccepted = acceptedHunkIDs.contains(hunk.id)

        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                diffColumn(title: "Synced Elsewhere", lines: hunk.removedLines, isStruckThrough: isAccepted)
                diffColumn(title: "This Device", lines: hunk.addedLines, isStruckThrough: !isAccepted)
            }

            Button {
                onToggle(hunk)
            } label: {
                Label(
                    isAccepted ? "Keeping This Device's Edit" : "Keeping Synced Edit",
                    systemImage: isAccepted ? "checkmark.circle.fill" : "circle"
                )
            }
            .buttonStyle(.bordered)
        }
        .padding(8)
        .background(Color.noteBytezSecondarySurface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func diffColumn(title: String, lines: [String], isStruckThrough: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if lines.isEmpty {
                Text("—")
                    .foregroundStyle(.tertiary)
            } else {
                Text(lines.joined(separator: "\n"))
                    .font(.body.monospaced())
                    .strikethrough(isStruckThrough)
                    .foregroundStyle(isStruckThrough ? .secondary : .primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

}
