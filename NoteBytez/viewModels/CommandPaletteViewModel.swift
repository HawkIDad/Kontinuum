// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CommandPaletteViewModel.swift
//  NoteBytez
//

import Foundation
import Observation

/// Backs `CommandPaletteView` (⌘P). No `ModelContext` — the palette is a registry over
/// `AppCommand.allCases` plus whatever plugin commands `loadPluginCommands` supplies, not a data
/// query. Routing is callback-injected rather than posting `NotificationCenter` directly, so
/// selection logic is unit-testable without a live app/scene; `ContentView` supplies the
/// callbacks that actually post `.noteBytez*` notifications.
@Observable
final class CommandPaletteViewModel {

    var query: String = "" {
        didSet { refreshResults() }
    }

    private(set) var results: [AppCommand] = AppCommand.allCases

    private var allCommands: [AppCommand] = AppCommand.allCases
    private let onNavigate: (AppDestination) -> Void
    private let onAction: (AppAction) -> Void
    private let onPluginCommand: (PluginCommand) -> Void
    private let pluginCommandLoader: () async -> [PluginCommand]

    init(
        onNavigate: @escaping (AppDestination) -> Void,
        onAction: @escaping (AppAction) -> Void,
        onPluginCommand: @escaping (PluginCommand) -> Void = { _ in },
        loadPluginCommands: @escaping () async -> [PluginCommand] = { [] }
    ) {
        self.onNavigate = onNavigate
        self.onAction = onAction
        self.onPluginCommand = onPluginCommand
        self.pluginCommandLoader = loadPluginCommands
    }

    func select(_ command: AppCommand) {
        switch command {
        case .navigate(let destination): onNavigate(destination)
        case .action(let action): onAction(action)
        case .plugin(let pluginCommand): onPluginCommand(pluginCommand)
        }
    }

    /// Appends every enabled plugin's registered commands after the built-ins. Async because a
    /// registration pass runs each plugin's script; the built-ins are usable before it returns.
    func loadPluginCommands() async {
        let pluginCommands = await pluginCommandLoader()
        allCommands = AppCommand.allCases + pluginCommands.map(AppCommand.plugin)
        refreshResults()
    }

    private func refreshResults() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            results = allCommands
            return
        }
        // Shorter titles rank above longer ones among equally-fuzzy-matching commands — e.g.
        // "newnote" fuzzy-matches both "New Note" and "New Notebook"; the shorter, more exact
        // match should be the top hit.
        results = allCommands
            .filter { $0.matches(query: trimmed) }
            .sorted { $0.title.count < $1.title.count }
    }

}
