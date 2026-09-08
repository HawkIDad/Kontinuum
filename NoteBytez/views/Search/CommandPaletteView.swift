// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CommandPaletteView.swift
//  NoteBytez
//

import SwiftUI

/// S26 — Command Palette (⌘P). Reuses `QuickSwitcherField`'s layout idiom (search-bar-in-
/// rounded-surface header + plain list) rather than a second presentation style for what is,
/// structurally, the same "type to filter, Return to act" affordance one level up from a
/// note-title jump.
struct CommandPaletteView: View {

    @Bindable var viewModel: CommandPaletteViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Type a command or search…", text: $viewModel.query)
                        .textFieldStyle(.plain)
                        .onSubmit(actOnTopHit)
                }
                .padding(10)
                .background(Color.noteBytezSecondarySurface)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding()

                if viewModel.results.isEmpty {
                    ContentUnavailableView.search
                } else {
                    List(viewModel.results) { command in
                        Button {
                            viewModel.select(command)
                            dismiss()
                        } label: {
                            CommandPaletteRow(command: command)
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Command Palette")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func actOnTopHit() {
        guard let topHit = viewModel.results.first else { return }
        viewModel.select(topHit)
        dismiss()
    }

}

/// One command row — icon + title, per `Docs/styleGuide.md`'s row conventions.
private struct CommandPaletteRow: View {

    let command: AppCommand

    var body: some View {
        Label(command.title, systemImage: command.systemImage)
            .frame(minHeight: 44)
    }

}
