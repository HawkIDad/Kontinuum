// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginViewModel.swift
//  Kontinuum
//

import Foundation
import SwiftData
import Observation

/// Backs S24 (Plugin Management): install/enable/disable/uninstall, plus running a plugin's
/// script against a fresh `PluginBridge` — command registration (`registeredCommands(for:)`, no
/// document open) and command invocation (`invokeCommand(_:on:documentViewModel:)`, against
/// whichever `DocumentViewModel` is currently open) each construct their own bridge.
@Observable
final class PluginViewModel {

    private(set) var plugins: [Plugin] = []
    let libraryId: UUID

    private let modelContext: ModelContext

    init(libraryId: UUID, modelContext: ModelContext) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        loadPlugins()
    }

    func loadPlugins() {
        plugins = PluginDAL.fetchActive(libraryId: libraryId, in: modelContext)
    }

    @discardableResult
    func install(name: String, entryScript: String, permissions: Set<PluginPermission>) -> Plugin? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedScript = entryScript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedScript.isEmpty else { return nil }

        let plugin = PluginDAL.install(name: trimmedName, entryScript: trimmedScript, permissions: permissions, libraryId: libraryId, in: modelContext)
        loadPlugins()
        return plugin
    }

    func setEnabled(_ plugin: Plugin, isEnabled: Bool) {
        PluginDAL.setEnabled(plugin, isEnabled: isEnabled, in: modelContext)
        loadPlugins()
    }

    /// "Revoke" per S24/Phase 13's own task list — a plugin's granted permissions aren't
    /// individually editable after install, so taking one back means removing the plugin
    /// entirely (soft-delete, per `PluginDAL.uninstall`).
    func uninstall(_ plugin: Plugin) {
        PluginDAL.uninstall(plugin, in: modelContext)
        loadPlugins()
    }

    /// The registration pass: runs `plugin`'s script with no invoked command, expecting it to
    /// call `noteBytez.addCommand(name)` for each command it offers. Returns whatever it
    /// self-reported; an empty result either means a script with no commands or one that failed
    /// (permission denial, script error, timeout) — this preview UI doesn't distinguish the two,
    /// consistent with how a disabled/ungranted plugin is meant to be silently inert rather than
    /// surfacing an error the user didn't ask for.
    func registeredCommands(for plugin: Plugin) async -> [String] {
        guard plugin.isEnabled == true else { return [] }
        let bridge = PluginBridge(entryScript: plugin.entryScript, grantedPermissions: plugin.grantedPermissions, snapshot: PluginLibrarySnapshot.capture(libraryId: libraryId, in: modelContext))
        guard await bridge.run(invokedCommand: nil) == .finished else { return [] }
        return bridge.collector.commands
    }

    /// Runs one specific command by name. On success, applies whatever the script's
    /// write-current-note calls collected onto `documentViewModel` (if one is open) — a script
    /// invoked with no document open (e.g. testing from the Plugin Management screen itself)
    /// simply has nowhere for those writes to land, so they're dropped rather than crashing.
    @discardableResult
    func invokeCommand(_ commandName: String, on plugin: Plugin, documentViewModel: DocumentViewModel?) async -> PluginRunResult {
        guard plugin.isEnabled == true else { return .scriptError("Plugin is disabled") }
        let bridge = PluginBridge(entryScript: plugin.entryScript, grantedPermissions: plugin.grantedPermissions, snapshot: PluginLibrarySnapshot.capture(libraryId: libraryId, in: modelContext))
        let result = await bridge.run(invokedCommand: commandName)
        if result == .finished {
            documentViewModel?.applyPluginWrites(appends: bridge.collector.appends, inserts: bridge.collector.inserts)
        }
        return result
    }

}
