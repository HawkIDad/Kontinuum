// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TagListRow.swift
//  NoteBytez
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
            Text(String(localized: "\(noteCount) note"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }

}
