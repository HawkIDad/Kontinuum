// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationAssistantView.swift
//  Kontinuum
//

import SwiftUI

/// S23 — Migration Assistant. Extends S2's Import Scan & Confirm pattern with a source-format
/// step first (per this phase's own plan wording): `MigrationSourceRow` at the top lets the user
/// confirm or correct the auto-detected tool, then the same "counts before any commitment" trust
/// moment S2 already establishes, format-specific (Obsidian's canvases vs. Logseq's journals/
/// unsupported queries). A sheet on every platform, same rule S2/S10/S15/S22 already follow for
/// a decision-bearing screen.
struct MigrationAssistantView: View {

    var viewModel: MigrationViewModel
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                MigrationSourceRow(
                    format: Binding(get: { viewModel.format }, set: { viewModel.setFormat($0) }),
                    wasAutoDetected: viewModel.wasAutoDetected
                )

                Divider()

                Text(summaryLine)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                Divider()

                List {
                    if !viewModel.scanResult.unsupportedQueries.isEmpty {
                        Section("Not Migrated — View Original Archive") {
                            ForEach(Array(viewModel.scanResult.unsupportedQueries.enumerated()), id: \.offset) { _, query in
                                Text(query)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.orange)
                                    .lineLimit(2)
                            }
                        }
                    }

                    Section("Notes") {
                        ForEach(viewModel.scanResult.pages) { file in
                            ImportFileRow(relativePath: file.relativePath, linkCount: file.linkCount, taskCount: file.taskCount)
                        }
                        ForEach(viewModel.scanResult.journalPages, id: \.summary.id) { entry in
                            ImportFileRow(relativePath: entry.summary.relativePath, linkCount: entry.summary.linkCount, taskCount: entry.summary.taskCount)
                        }
                    }

                    if !viewModel.scanResult.canvasFiles.isEmpty {
                        Section("Canvases") {
                            ForEach(viewModel.scanResult.canvasFiles) { canvasFile in
                                Text(canvasFile.relativePath)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Migration Assistant")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelMigration()
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm Migration") {
                        viewModel.confirmMigration()
                        onConfirm()
                    }
                    .disabled(viewModel.scanResult.noteCount == 0)
                }
            }
        }
    }

    private var summaryLine: String {
        let result = viewModel.scanResult
        var parts = ["\(result.noteCount) note\(result.noteCount == 1 ? "" : "s")", "\(result.linkCount) link\(result.linkCount == 1 ? "" : "s")"]
        switch result.format {
        case .obsidian:
            parts.append("\(result.canvasCount) canvas\(result.canvasCount == 1 ? "" : "es")")
        case .logseq:
            parts.append("\(result.taskCount) task\(result.taskCount == 1 ? "" : "s")")
            parts.append("\(result.journalCount) journal entr\(result.journalCount == 1 ? "y" : "ies")")
            if result.unsupportedCount > 0 {
                parts.append("\(result.unsupportedCount) unsupported item\(result.unsupportedCount == 1 ? "" : "s") flagged")
            }
        }
        return parts.joined(separator: " · ")
    }

}

/// `MigrationSourceRow` (Phase 1's S23 component inventory): format selector + detected-format
/// summary. Segmented rather than radio buttons (this codebase has no radio-button control
/// established elsewhere) — same two mutually-exclusive choices the wireframe's radio group
/// expresses, an accepted platform-idiom deviation matching prior phases' own precedent for
/// translating an ASCII wireframe into a native control.
struct MigrationSourceRow: View {

    @Binding var format: MigrationSourceFormat
    let wasAutoDetected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Source", selection: $format) {
                ForEach(MigrationSourceFormat.allCases) { format in
                    Text(format.displayName).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            Text(wasAutoDetected ? "Auto-detected: \(format.displayName) vault" : "Couldn't auto-detect this vault's format — confirm above")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

}
