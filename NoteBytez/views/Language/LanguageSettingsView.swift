// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LanguageSettingsView.swift
//  NoteBytez
//

import SwiftUI

/// Settings → Language. Sourced from `SupportedLocales` (never offers an untranslated locale)
/// plus "System Default". Per NoteBytez20260823v2-MultiLanguage.md decision G4a: unlike the
/// first-launch prompt (5.4), the view hierarchy is already live by the time this screen is
/// reachable, so a change here needs the documented restart to actually apply.
struct LanguageSettingsView: View {

    @State private var selectedId: String?

    init() {
        _selectedId = State(initialValue: LocalePreferenceStore.preferredLanguageCode())
    }

    var body: some View {
        List {
            Section {
                // "System Default" is UI chrome (localizable); an endonym ("Deutsch") is the
                // language's own invariant name for itself and must never be re-localized — the
                // two can't share one `String`-typed helper parameter without repeating Phase
                // 2.1's `Text(String)`-is-verbatim bug, so `row` takes a pre-built `Text`.
                row(title: Text("System Default"), isSelected: selectedId == nil) {
                    selectedId = nil
                    LocalePreferenceStore.setPreferredLanguageCode(nil)
                }
                .accessibilityIdentifier("languageSettings.option.system")

                ForEach(SupportedLocales.all) { locale in
                    row(title: Text(locale.endonym), isSelected: selectedId == locale.id) {
                        selectedId = locale.id
                        LocalePreferenceStore.setPreferredLanguageCode(locale.id)
                    }
                    .accessibilityIdentifier("languageSettings.option.\(locale.id)")
                }
            } footer: {
                Text("Changes take effect after restart.")
            }
        }
        .navigationTitle("Language")
        .noteBytezInlineNavigationTitle()
    }

    private func row(title: Text, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                title
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

}

#Preview {
    NavigationStack {
        LanguageSettingsView()
    }
}
