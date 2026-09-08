// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphNode.swift
//  NoteBytez
//

import SwiftUI

/// S8's node glyph: filled when it's the current note, outlined otherwise, per
/// UIUX/06-DesignSystem.md's component inventory.
struct GraphNode: View {

    let title: String
    let isCenter: Bool

    @State private var isHovering = false

    private var diameter: CGFloat { isCenter ? 20 : 14 }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().fill(isCenter ? Color.accentColor : Color.clear)
                Circle().stroke(Color.accentColor, lineWidth: 2)
            }
            .frame(width: diameter, height: diameter)
            .scaleEffect(isHovering ? 1.3 : 1.0)

            Text(title)
                .font(.caption)
                .lineLimit(1)
                .fixedSize()
        }
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        // Mac/trackpad users get pointer hover as a discovery cue in place of iOS's
        // tap-and-hold — a no-op gesture on touch-only platforms.
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(isCenter ? "Current note, \(title)" : "Linked note, \(title)")
    }

}
