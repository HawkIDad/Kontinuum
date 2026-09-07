// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskCheckbox.swift
//  Kontinuum
//

import SwiftUI

/// Two-state checkbox bound to `- [ ]`/`- [x]`, per docs/styleGuide.md's icon set
/// (`square`/`checkmark.square.fill`). A real button rather than a tappable text run — unlike
/// wikilinks/tags, which are only ever rendered inline inside an `AttributedString`, a task's
/// primary interaction is the toggle itself, and it needs a reliable, sizeable tap target.
struct TaskCheckbox: View {

    let label: String
    let isDone: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isDone ? "checkmark.square.fill" : "square")
                .foregroundStyle(isDone ? Color.accentColor : Color.secondary)
                .frame(minWidth: 44, minHeight: 44, alignment: .center)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityValue(isDone ? "Done" : "Not done")
        .accessibilityAddTraits(.isButton)
    }

}
