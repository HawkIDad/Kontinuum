// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  FirstLaunchLanguagePromptView.swift
//  NoteBytez
//

import SwiftUI

/// The very first thing `RootView` shows — before even the entitlement gate — per
/// NoteBytez20260823v2-MultiLanguage.md decision G4b: a user should be able to read the paywall
/// in their own language. Shown exactly once (gated by `LocalePreferenceStore.hasPromptedForLanguage`
/// in `RootView`), offers only `SupportedLocales.all`, and applies immediately on confirm — no
/// restart, since nothing has rendered yet for a stale value to linger in.
struct FirstLaunchLanguagePromptView: View {

    @State private var selection: SupportedLocale
    let onConfirm: () -> Void

    init(onConfirm: @escaping () -> Void) {
        self.onConfirm = onConfirm
        _selection = State(initialValue: SupportedLocales.matchingDevice())
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Text("Choose Your Language")
                        .font(.title2.bold())
                    Text("You can change this later in Settings.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding(.top, 40)
                .padding(.horizontal)

                List(SupportedLocales.all) { locale in
                    Button {
                        selection = locale
                    } label: {
                        HStack {
                            Text(locale.endonym)
                                .foregroundStyle(.primary)
                            Spacer()
                            if selection.id == locale.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .accessibilityIdentifier("languagePrompt.option.\(locale.id)")
                    .accessibilityAddTraits(selection.id == locale.id ? [.isButton, .isSelected] : .isButton)
                }
                .listStyle(.plain)

                PrimaryButton(title: "Continue") {
                    LocalePreferenceStore.setPreferredLanguageCode(selection.id)
                    LocalePreferenceStore.markPromptedForLanguage()
                    onConfirm()
                }
                .padding()
            }
        }
    }

}

#Preview {
    FirstLaunchLanguagePromptView(onConfirm: {})
}
