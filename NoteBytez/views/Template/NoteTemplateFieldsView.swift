// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NoteTemplateFieldsView.swift
//  NoteBytez
//

import SwiftUI

/// S18 Manager, level 3 — the Property fields one `NoteTemplate` pre-fills.
struct NoteTemplateFieldsView: View {

    var viewModel: TemplateViewModel
    let template: NoteTemplate

    @State private var fields: [NoteTemplateField] = []
    @State private var newFieldName = ""
    @State private var newFieldType: PropertyValueType = .text
    @State private var newFieldDefault = ""

    var body: some View {
        List {
            Section("Fields") {
                if fields.isEmpty {
                    ContentUnavailableView(
                        "No Fields Yet",
                        systemImage: "list.bullet.rectangle",
                        description: Text("Add a field below — every new note from this template starts with it pre-filled.")
                    )
                } else {
                    ForEach(fields) { field in
                        HStack {
                            Text(field.name)
                            Spacer()
                            Text(field.valueType.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(minHeight: 44)
                    }
                    .onDelete { offsets in
                        fields.remove(atOffsets: offsets)
                        commit()
                    }
                }
            }

            Section("Add Field") {
                TextField("Field name", text: $newFieldName)
                Picker("Type", selection: $newFieldType) {
                    ForEach(PropertyValueType.allCases, id: \.self) { valueType in
                        Text(valueType.rawValue.capitalized).tag(valueType)
                    }
                }
                TextField("Default value (optional)", text: $newFieldDefault)
                Button("Add Field") {
                    fields.append(NoteTemplateField(name: newFieldName.trimmingCharacters(in: .whitespacesAndNewlines), valueType: newFieldType, defaultValue: newFieldDefault))
                    newFieldName = ""
                    newFieldDefault = ""
                    newFieldType = .text
                    commit()
                }
                .disabled(newFieldName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle(template.name ?? "Template")
        .noteBytezInlineNavigationTitle()
        .onAppear { fields = template.fields }
    }

    private func commit() {
        viewModel.updateFields(template, fields: fields)
    }

}
