// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CommandPaletteViewModel.swift
//  Kontinuum
//

import Foundation
import Observation

/// Backs `CommandPaletteView` (⌘P). No `ModelContext` — the palette is a static registry over
/// `AppCommand.allCases`, not a data query. Routing is callback-injected rather than posting
/// `NotificationCenter` directly, so selection logic is unit-testable without a live app/scene;
/// `ContentView` supplies the callbacks that actually post `.kontinuum*` notifications.
@Observable
final class CommandPaletteViewModel {

    var query: String = "" {
        didSet { refreshResults() }
    }

    private(set) var results: [AppCommand] = AppCommand.allCases

    private let onNavigate: (AppDestination) -> Void
    private let onAction: (AppAction) -> Void

    init(onNavigate: @escaping (AppDestination) -> Void, onAction: @escaping (AppAction) -> Void) {
        self.onNavigate = onNavigate
        self.onAction = onAction
    }

    func select(_ command: AppCommand) {
        switch command {
        case .navigate(let destination): onNavigate(destination)
        case .action(let action): onAction(action)
        }
    }

    private func refreshResults() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = AppCommand.allCases
            return
        }
        // Shorter titles rank above longer ones among equally-fuzzy-matching commands — e.g.
        // "newnote" fuzzy-matches both "New Note" and "New Notebook"; the shorter, more exact
        // match should be the top hit.
        results = AppCommand.allCases
            .filter { $0.matches(query: trimmed) }
            .sorted { $0.title.count < $1.title.count }
    }

}
