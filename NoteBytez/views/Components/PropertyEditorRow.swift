// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PropertyEditorRow.swift
//  Kontinuum
//

import SwiftUI

/// Typed field row (text/number/date/checkbox/list), inline in S4's Properties block — per
/// docs/styleGuide.md. Both labels and edits the value in one component, so there's no
/// separate read-only "field" component to keep in sync with an editable one.
struct PropertyEditorRow: View {

    let name: String
    let valueType: PropertyValueType
    @Binding var value: String
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(name)
                .font(.body)
            Spacer()
            field
                .multilineTextAlignment(.trailing)
                .foregroundStyle(.secondary)
            Button(role: .destructive, action: onRemove) {
                Image(systemName: "minus.circle")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remove \(name)")
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var field: some View {
        switch valueType {
        case .checkbox:
            Toggle(isOn: checkboxBinding) { EmptyView() }
                .labelsHidden()
        case .list:
            TextField("item, item", text: listBinding)
        case .text, .number, .date:
            TextField(placeholder, text: $value)
        }
    }

    private var placeholder: String {
        switch valueType {
        case .number: return "0"
        case .date: return "yyyy-MM-dd"
        default: return "Value"
        }
    }

    private var checkboxBinding: Binding<Bool> {
        Binding(
            get: { value.caseInsensitiveCompare("true") == .orderedSame },
            set: { value = $0 ? "true" : "false" }
        )
    }

    /// `DocumentProperty.value`'s canonical list form is "; "-joined (see `PropertyParser`) —
    /// this presents/edits it as an ordinary comma-separated field instead of asking the user
    /// to type a semicolon.
    private var listBinding: Binding<String> {
        Binding(
            get: { value.replacingOccurrences(of: "; ", with: ", ") },
            set: { newValue in
                value = newValue.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                    .joined(separator: "; ")
            }
        )
    }

}
