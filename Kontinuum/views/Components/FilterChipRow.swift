// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  FilterChipRow.swift
//  Kontinuum
//

import SwiftUI

/// Horizontal scoped-filter toggles — mutually exclusive, per docs/styleGuide.md. Generic over
/// any simple `String`-backed `CaseIterable` enum (originally `SearchViewModel.Scope` only;
/// genericized in Phase 6 so the Task Dashboard's status/date filters reuse this instead of a
/// second, copy-pasted chip row).
struct FilterChipRow<Scope>: View where Scope: CaseIterable, Scope: Identifiable, Scope: Hashable, Scope: RawRepresentable, Scope.RawValue == String {

    let scopes: [Scope]
    @Binding var selected: Scope

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(scopes) { scope in
                    Button(scope.rawValue) {
                        selected = scope
                    }
                    .buttonStyle(.bordered)
                    .tint(scope == selected ? .accentColor : .secondary)
                    .controlSize(.small)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
            }
        }
    }

}
