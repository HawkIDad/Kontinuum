// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  RecurrenceControl.swift
//  NoteBytez
//

import SwiftUI

/// Badge for a task's repeat interval, per docs/styleGuide.md.
struct RecurrenceControl: View {

    let rule: RecurrenceRule

    var body: some View {
        Label(rule.displayName, systemImage: "arrow.triangle.2.circlepath")
            .font(.caption)
            .foregroundStyle(.secondary)
    }

}
