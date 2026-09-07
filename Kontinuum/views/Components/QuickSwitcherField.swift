// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  QuickSwitcherField.swift
//  Kontinuum
//

import SwiftUI

/// Search input with fuzzy result list, keyboard-navigable, per docs/styleGuide.md.
struct QuickSwitcherField: View {

    @Binding var query: String
    let results: [Document]
    let onSelect: (Document) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search notes...", text: $query)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color.noteBytezSecondarySurface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding()

            if results.isEmpty {
                ContentUnavailableView.search
            } else {
                List(results) { document in
                    Button {
                        onSelect(document)
                    } label: {
                        Text(document.title?.isEmpty == false ? document.title! : "Untitled")
                    }
                    .buttonStyle(.plain)
                }
                .listStyle(.plain)
            }
        }
    }

}
