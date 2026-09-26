// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// The outcome of a plugin's registration pass: the commands it offered, or why it offered none.
struct PluginRegistration: Equatable {

    let commands: [String]
    let failure: String?

}

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
        await registration(for: plugin).commands
    }

    /// `registeredCommands(for:)` plus *why* it came back empty, when it did: a script error or
    /// timeout, or a script that ran cleanly but never called `addCommand`. A disabled plugin is
    /// deliberately inert, so it reports no failure.
    func registration(for plugin: Plugin) async -> PluginRegistration {
        guard plugin.isEnabled == true else { return PluginRegistration(commands: [], failure: nil) }
        let bridge = PluginBridge(entryScript: plugin.entryScript, grantedPermissions: plugin.grantedPermissions, snapshot: PluginLibrarySnapshot.capture(libraryId: libraryId, in: modelContext))
        let result = await bridge.run(invokedCommand: nil)
        let pluginName = plugin.name ?? ""
        if let failure = Self.failureDescription(for: result, pluginName: pluginName) {
            return PluginRegistration(commands: [], failure: failure)
        }
        let commands = bridge.collector.commands
        guard commands.isEmpty else { return PluginRegistration(commands: commands, failure: nil) }
        return PluginRegistration(commands: [], failure: "\"\(pluginName)\" ran but registered no commands. Call noteBytez.addCommand(name) with the Add command permission granted.")
    }

    /// Every enabled plugin's registered commands, in install order — what the Command Palette
    /// lists after the built-ins. A plugin that fails to register contributes nothing here; its
    /// reason is surfaced by `registrationFailures()` in Plugin Management.
    func availableCommands() async -> [PluginCommand] {
        var pluginCommands: [PluginCommand] = []
        for plugin in plugins {
            let names = await registeredCommands(for: plugin)
            pluginCommands += names.map { PluginCommand(pluginId: plugin.id, pluginName: plugin.name ?? "", commandName: $0) }
        }
        return pluginCommands
    }

    /// Registration failure messages keyed by `pluginId`, for enabled plugins that failed to
    /// register — shown as a caption under the plugin in Plugin Management.
    func registrationFailures() async -> [UUID: String] {
        var failures: [UUID: String] = [:]
        for plugin in plugins {
            if let failure = await registration(for: plugin).failure { failures[plugin.id] = failure }
        }
        return failures
    }

    /// Runs a palette-selected command. The plugin is looked up again at run time — it may have
    /// been disabled or uninstalled since the palette loaded.
    @discardableResult
    func invokeCommand(_ command: PluginCommand, documentViewModel: DocumentViewModel?) async -> PluginRunResult {
        guard let plugin = plugins.first(where: { $0.id == command.pluginId }) else {
            return .scriptError("Plugin is no longer installed")
        }
        return await invokeCommand(command.commandName, on: plugin, documentViewModel: documentViewModel)
    }

    /// User-facing text for a failed run, or `nil` when it finished cleanly.
    static func failureDescription(for result: PluginRunResult, pluginName: String) -> String? {
        switch result {
        case .finished:
            return nil
        case .scriptError(let message):
            return "\"\(pluginName)\" failed: \(message)"
        case .timedOut:
            return "\"\(pluginName)\" took longer than \(Int(PluginBridge.executionTimeLimit)) seconds and was stopped."
        }
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
