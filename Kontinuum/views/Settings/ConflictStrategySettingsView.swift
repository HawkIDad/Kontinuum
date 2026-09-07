// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictStrategySettingsView.swift
//  Kontinuum
//

import SwiftUI

/// S11 — Settings: Conflict Strategy. Three mutually-exclusive options, always-visible
/// one-line descriptions — "a trust-critical decision... must not read as a technical/
/// default-hidden setting," per the wireframe.
struct ConflictStrategySettingsView: View {

    @State private var selectedStrategy = ConflictStrategyStore.currentStrategy()

    var body: some View {
        List {
            Section("Conflict resolution strategy") {
                ForEach(ConflictStrategy.allCases) { strategy in
                    SettingsRadioRow(
                        title: strategy.title,
                        description: strategy.summary,
                        isSelected: selectedStrategy == strategy
                    ) {
                        selectedStrategy = strategy
                        ConflictStrategyStore.setCurrentStrategy(strategy)
                    }
                }
            }
        }
        .navigationTitle("Sync & Conflicts")
        .noteBytezInlineNavigationTitle()
    }

}
