// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  UndoToast.swift
//  NoteBytez
//

import SwiftUI

/// Transient "Resolved — Undo" strip shown for `ConflictStore.undoWindow` after a manual
/// conflict resolution (`Docs/Bugs/20260910v1-Sync.md` SF 7). It clears itself when the window
/// lapses (the store nils `pendingUndo`) or when the user taps Undo; there is no dismiss
/// control because letting it lapse *is* the confirm.
struct UndoToast: View {

    let title: String
    let onUndo: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)

            Text("Resolved \"\(title)\"")
                .font(.callout)

            Spacer(minLength: 8)

            Button("Undo", action: onUndo)
                .font(.callout.weight(.semibold))
        }
        .padding()
        .background(Color.green.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Resolved \(title). Undo available.")
    }

}
