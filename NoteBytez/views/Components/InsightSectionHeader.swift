// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  InsightSectionHeader.swift
//  NoteBytez
//

import SwiftUI

/// One `GraphInsightsView` category header — title, count, and a one-line "what this means"
/// explanation, per `Docs/styleGuide.md`'s convention of never leaving a category unexplained.
struct InsightSectionHeader: View {

    let title: String
    let count: Int
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title)
                Spacer()
                Text("\(count)")
                    .foregroundStyle(.secondary)
            }
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

}
