// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportScanView.swift
//  NoteBytez
//

import SwiftUI

/// S2 — Import Scan & Confirm. Summary counts must be visible before any commitment — per
/// Journey 1, this is the trust-building moment — so nothing is written until "Confirm Import"
/// is tapped.
struct ImportScanView: View {

    var viewModel: ImportViewModel
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ImportSummaryHeader(noteCount: viewModel.noteCount, linkCount: viewModel.linkCount, taskCount: viewModel.taskCount, notebookCount: viewModel.notebookCount)

                Divider()

                if viewModel.files.isEmpty {
                    ContentUnavailableView(
                        "No Markdown Files Found",
                        systemImage: "doc.text",
                        description: Text("This folder doesn't contain any .md files.")
                    )
                } else {
                    List(viewModel.files) { file in
                        ImportFileRow(relativePath: file.relativePath, linkCount: file.linkCount, taskCount: file.taskCount)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Import Preview")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.cancelImport()
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm Import") {
                        viewModel.confirmImport()
                        onConfirm()
                    }
                    .disabled(viewModel.files.isEmpty)
                }
            }
        }
    }

}
