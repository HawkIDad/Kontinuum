// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagListRow.swift
//  Kontinuum
//

import SwiftUI

/// Tag name + note count, per docs/styleGuide.md.
struct TagListRow: View {

    let name: String
    let noteCount: Int

    var body: some View {
        HStack {
            Text("#\(name)")
                .font(.body)
            Spacer()
            Text("\(noteCount) note\(noteCount == 1 ? "" : "s")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

}
