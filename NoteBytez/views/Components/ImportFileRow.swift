// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportFileRow.swift
//  NoteBytez
//

import SwiftUI

/// Filename + per-file link/task counts, per docs/styleGuide.md.
struct ImportFileRow: View {

    let relativePath: String
    let linkCount: Int
    let taskCount: Int

    var body: some View {
        HStack {
            Text(relativePath)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
            Text("\(linkCount)L · \(taskCount)T")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

}
