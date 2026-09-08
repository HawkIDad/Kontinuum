// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginDALTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

struct PluginDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Plugin.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func installStoresNameScriptAndGrantedPermissions() throws {
        let context = try makeContext()
        let libraryId = UUID()

        let plugin = PluginDAL.install(name: "Word Count", entryScript: "noteBytez.addCommand('x');", permissions: [.readLibrary, .writeCurrentNote], libraryId: libraryId, in: context)

        #expect(plugin.name == "Word Count")
        #expect(plugin.entryScript == "noteBytez.addCommand('x');")
        #expect(plugin.grantedPermissions == [.readLibrary, .writeCurrentNote])
        #expect(plugin.isEnabled == true)
        #expect(plugin.isActive == true)
    }

    @Test func installGrantsNoPermissionsWhenNoneRequested() throws {
        let context = try makeContext()
        let plugin = PluginDAL.install(name: "Inert", entryScript: "1;", permissions: [], libraryId: UUID(), in: context)

        #expect(plugin.grantedPermissions.isEmpty)
    }

    @Test func fetchActiveExcludesOtherLibraries() throws {
        let context = try makeContext()
        PluginDAL.install(name: "Mine", entryScript: "1;", permissions: [], libraryId: UUID(), in: context)

        #expect(PluginDAL.fetchActive(libraryId: UUID(), in: context).isEmpty)
    }

    @Test func fetchActiveExcludesUninstalledPlugins() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let plugin = PluginDAL.install(name: "Mine", entryScript: "1;", permissions: [], libraryId: libraryId, in: context)

        PluginDAL.uninstall(plugin, in: context)

        #expect(PluginDAL.fetchActive(libraryId: libraryId, in: context).isEmpty)
    }

    @Test func setEnabledTogglesTheFlag() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let plugin = PluginDAL.install(name: "Mine", entryScript: "1;", permissions: [], libraryId: libraryId, in: context)

        PluginDAL.setEnabled(plugin, isEnabled: false, in: context)
        #expect(plugin.isEnabled == false)

        PluginDAL.setEnabled(plugin, isEnabled: true, in: context)
        #expect(plugin.isEnabled == true)
    }

    @Test func uninstallSoftDeletesRatherThanRemoving() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let plugin = PluginDAL.install(name: "Gone Soon", entryScript: "1;", permissions: [], libraryId: libraryId, in: context)

        PluginDAL.uninstall(plugin, in: context)

        #expect(plugin.isActive == false)
        let allRecords = try context.fetch(FetchDescriptor<Plugin>())
        #expect(allRecords.count == 1)
    }

}
