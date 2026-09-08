// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  SettingsRadioRow.swift
//  NoteBytez
//

import SwiftUI

/// S11's strategy picker row — radio selector, title, one-line plain-language description.
/// "This is a trust-critical decision and must not read as a technical/default-hidden
/// setting" — per `05-Wireframes.md`, hence the description is always visible, not a tooltip.
struct SettingsRadioRow: View {

    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

}
