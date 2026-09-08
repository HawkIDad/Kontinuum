// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  QuickSwitcherView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData

/// S6 — Quick Switcher. Fast fuzzy note-title jump, presented as a full-screen modal — matches
/// UIUX/05-Wireframes.md's iPhone/iPad treatment (Mac/iPad would float this as an overlay
/// palette, but a plain sheet is the one presentation style that works identically everywhere,
/// which is what MVP ships).
struct QuickSwitcherView: View {

    var viewModel: SearchViewModel
    let onSelect: (Document) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            QuickSwitcherField(
                query: $query,
                results: viewModel.quickSwitcherResults(query: query),
                onSelect: { document in
                    onSelect(document)
                    dismiss()
                }
            )
            .navigationTitle("Quick Switcher")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

}
