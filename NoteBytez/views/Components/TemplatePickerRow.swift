// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplatePickerRow.swift
//  NoteBytez
//

import SwiftUI

/// Template name + icon, tappable — per docs/styleGuide.md. Used in the Template Picker
/// (grouped by `TemplateGroup`) and reused, in an editable `List`, for the Template Manager.
struct TemplatePickerRow: View {

    let name: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "doc.badge.plus")
                Text(name)
                Spacer()
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

}
