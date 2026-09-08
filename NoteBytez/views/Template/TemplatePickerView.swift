// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplatePickerView.swift
//  Kontinuum
//

import SwiftUI

/// S18 — Template Picker. A decision the user must complete or cancel before continuing (which
/// template, or none), so it's a modal sheet on every platform — same rule S2/S10/S15/S22
/// follow.
struct TemplatePickerView: View {

    let scope: TemplateDAL.PickerScope
    var viewModel: TemplateViewModel
    /// `nil` means the explicit "start blank" choice — never omitted silently, per S18's
    /// Elements: a picker never auto-commits.
    let onSelect: (NoteTemplate?) -> Void
    var showsStartBlankOption: Bool = true

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.pickerSections(scope: scope)) { section in
                    Section(section.group.name ?? "") {
                        ForEach(section.templates) { template in
                            TemplatePickerRow(name: template.name ?? "") {
                                onSelect(template)
                                dismiss()
                            }
                        }
                    }
                }

                if showsStartBlankOption {
                    Section {
                        Button("Start Blank (no template)") {
                            onSelect(nil)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Choose a Template")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

}
