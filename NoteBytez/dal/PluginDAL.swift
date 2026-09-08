// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginDAL.swift
//  NoteBytez
//

import Foundation
import SwiftData

/// CRUD for installed `Plugin` rows. The permissioned `JavaScriptCore` bridge itself lives in
/// `PluginBridge`, not here — this DAL only manages the manifest (name/script/granted
/// permissions/enabled state), matching how `TemplateDAL` owns `NoteTemplate` CRUD while a
/// separate concern (apply-at-creation) does the actual content work.
enum PluginDAL {

    @discardableResult
    static func install(name: String, entryScript: String, permissions: Set<PluginPermission>, libraryId: UUID, in context: ModelContext) -> Plugin {
        let plugin = Plugin(name: name, libraryId: libraryId, entryScript: entryScript, permissions: permissions)
        context.insert(plugin)
        SyncEngine.shared.recordChanged(plugin, in: context)
        return plugin
    }

    static func fetchActive(libraryId: UUID, in context: ModelContext) -> [Plugin] {
        let predicate = #Predicate<Plugin> { $0.libraryId == libraryId && $0.isActive == true }
        let descriptor = FetchDescriptor<Plugin>(predicate: predicate, sortBy: [SortDescriptor(\.createdOn)])
        return (try? context.fetch(descriptor)) ?? []
    }

    static func setEnabled(_ plugin: Plugin, isEnabled: Bool, in context: ModelContext) {
        plugin.isEnabled = isEnabled
        plugin.updatedOn = Date()
        SyncEngine.shared.recordChanged(plugin, in: context)
    }

    /// Revokes the plugin entirely (soft-delete, per the app's no-physical-deletes rule) — the
    /// only way to take back a granted permission, since permissions aren't editable
    /// individually after install (see `Plugin`'s own design note).
    static func uninstall(_ plugin: Plugin, in context: ModelContext) {
        plugin.isActive = false
        plugin.updatedOn = Date()
        SyncEngine.shared.recordChanged(plugin, in: context)
    }

}
