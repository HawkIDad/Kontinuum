// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphInsightRow.swift
//  Kontinuum
//

import SwiftUI

/// One `GraphInsightsView` document row — title plus whatever metric its category is ranked
/// by (last-edited, open-task count + due date, link degree). The metric is always shown as
/// icon + text, never color alone, per `Docs/styleGuide.md`'s color-blind-safe convention.
struct GraphInsightRow: View {

    let title: String
    let detail: String
    var systemImage: String = "doc.text"

    var body: some View {
        HStack(spacing: 8) {
            Label(title.isEmpty ? "Untitled" : title, systemImage: systemImage)
            Spacer()
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 44)
    }

}
