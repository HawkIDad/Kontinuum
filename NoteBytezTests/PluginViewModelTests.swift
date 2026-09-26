// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginViewModelTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct PluginViewModelTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, TaskItem.self, Property.self, DocumentProperty.self, Plugin.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    @Test func installTrimsWhitespaceAndRejectsAnEmptyNameOrScript() throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)

        let installed = viewModel.install(name: "  Word Count  ", entryScript: "  noteBytez.addCommand('x');  ", permissions: [.readLibrary])

        #expect(installed?.name == "Word Count")
        #expect(installed?.entryScript == "noteBytez.addCommand('x');")
        #expect(viewModel.install(name: "", entryScript: "1;", permissions: []) == nil)
        #expect(viewModel.install(name: "No Script", entryScript: "   ", permissions: []) == nil)
        #expect(viewModel.plugins.count == 1)
    }

    @Test func setEnabledAndUninstallUpdateThePluginList() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = PluginViewModel(libraryId: libraryId, modelContext: context)
        let plugin = try #require(viewModel.install(name: "Mine", entryScript: "1;", permissions: []))

        viewModel.setEnabled(plugin, isEnabled: false)
        #expect(viewModel.plugins.first?.isEnabled == false)

        viewModel.uninstall(plugin)
        #expect(viewModel.plugins.isEmpty)
    }

    @Test func registeredCommandsReturnsWhatTheScriptSelfReports() async throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = PluginViewModel(libraryId: libraryId, modelContext: context)
        let plugin = try #require(viewModel.install(
            name: "Word Count",
            entryScript: "noteBytez.addCommand('Insert Word Count');",
            permissions: [.addCommand]
        ))

        #expect(await viewModel.registeredCommands(for: plugin) == ["Insert Word Count"])
    }

    @Test func registeredCommandsIsEmptyForADisabledPlugin() async throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = PluginViewModel(libraryId: libraryId, modelContext: context)
        let plugin = try #require(viewModel.install(name: "Word Count", entryScript: "noteBytez.addCommand('x');", permissions: [.addCommand]))
        viewModel.setEnabled(plugin, isEnabled: false)

        let commands = await viewModel.registeredCommands(for: plugin)
        #expect(commands.isEmpty)
    }

    @Test func invokeCommandAppliesCollectedWritesToTheOpenDocument() async throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Notes", content: "Existing line", libraryId: libraryId, in: context)
        let documentViewModel = DocumentViewModel(document: document, modelContext: context)
        let viewModel = PluginViewModel(libraryId: libraryId, modelContext: context)
        let plugin = try #require(viewModel.install(
            name: "Word Count",
            entryScript: """
            if (noteBytez.invokedCommand === "Insert Word Count") {
                noteBytez.appendToCurrentNote("Library has " + noteBytez.listDocuments().length + " notes.");
            }
            """,
            permissions: [.readLibrary, .writeCurrentNote]
        ))

        let result = await viewModel.invokeCommand("Insert Word Count", on: plugin, documentViewModel: documentViewModel)

        #expect(result == .finished)
        #expect(documentViewModel.content.contains("Library has 1 notes."))
    }

    @Test func invokeCommandOnADisabledPluginDoesNothing() async throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Notes", content: "Existing line", libraryId: libraryId, in: context)
        let documentViewModel = DocumentViewModel(document: document, modelContext: context)
        let viewModel = PluginViewModel(libraryId: libraryId, modelContext: context)
        let plugin = try #require(viewModel.install(name: "Mine", entryScript: "noteBytez.appendToCurrentNote('x');", permissions: [.writeCurrentNote]))
        viewModel.setEnabled(plugin, isEnabled: false)

        let result = await viewModel.invokeCommand("Anything", on: plugin, documentViewModel: documentViewModel)

        guard case .scriptError = result else {
            Issue.record("Expected .scriptError for a disabled plugin")
            return
        }
        #expect(documentViewModel.content == "Existing line")
    }

    @Test func invokeCommandWithNoOpenDocumentDropsTheWritesWithoutCrashing() async throws {
        let context = try makeContext()
        let libraryId = UUID()
        let viewModel = PluginViewModel(libraryId: libraryId, modelContext: context)
        let plugin = try #require(viewModel.install(name: "Mine", entryScript: "noteBytez.appendToCurrentNote('x');", permissions: [.writeCurrentNote]))

        let result = await viewModel.invokeCommand("Anything", on: plugin, documentViewModel: nil)

        #expect(result == .finished)
    }

    // MARK: Command-palette surface

    @Test func availableCommandsListsEnabledPluginsCommandsWithThePluginName() async throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)
        let plugin = try #require(viewModel.install(name: "Word Count", entryScript: "noteBytez.addCommand('Insert');noteBytez.addCommand('Reset');", permissions: [.addCommand]))
        let disabled = try #require(viewModel.install(name: "Off", entryScript: "noteBytez.addCommand('Hidden');", permissions: [.addCommand]))
        viewModel.setEnabled(disabled, isEnabled: false)

        let commands = await viewModel.availableCommands()

        #expect(commands.map(\.commandName) == ["Insert", "Reset"])
        #expect(commands.allSatisfy { $0.pluginName == "Word Count" && $0.pluginId == plugin.id })
    }

    @Test func availableCommandsSkipsAPluginWhoseScriptFails() async throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)
        viewModel.install(name: "Broken", entryScript: "this is not javascript(", permissions: [.addCommand])

        #expect(await viewModel.availableCommands().isEmpty)
    }

    @Test func registrationReportsAScriptErrorAsAFailureMessage() async throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)
        let plugin = try #require(viewModel.install(name: "Broken", entryScript: "throw new Error('boom');", permissions: [.addCommand]))

        let registration = await viewModel.registration(for: plugin)

        #expect(registration.commands.isEmpty)
        #expect(registration.failure?.contains("boom") == true)
    }

    @Test func registrationReportsAMissingPermissionAsAFailureMessage() async throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)
        let plugin = try #require(viewModel.install(name: "NoGrant", entryScript: "noteBytez.addCommand('x');", permissions: []))

        let registration = await viewModel.registration(for: plugin)

        #expect(registration.failure?.contains("Permission denied") == true)
    }

    @Test func registrationReportsAScriptThatRegistersNothing() async throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)
        let plugin = try #require(viewModel.install(name: "Quiet", entryScript: "var x = 1;", permissions: [.addCommand]))

        let registration = await viewModel.registration(for: plugin)

        #expect(registration.commands.isEmpty)
        #expect(registration.failure?.contains("addCommand") == true)
    }

    @Test func registrationOfASuccessfulPluginHasNoFailure() async throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)
        let plugin = try #require(viewModel.install(name: "Good", entryScript: "noteBytez.addCommand('x');", permissions: [.addCommand]))

        let registration = await viewModel.registration(for: plugin)

        #expect(registration.commands == ["x"])
        #expect(registration.failure == nil)
    }

    @Test func registrationOfADisabledPluginIsEmptyWithNoFailure() async throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)
        let plugin = try #require(viewModel.install(name: "Off", entryScript: "noteBytez.addCommand('x');", permissions: [.addCommand]))
        viewModel.setEnabled(plugin, isEnabled: false)

        let registration = await viewModel.registration(for: plugin)

        #expect(registration.commands.isEmpty)
        #expect(registration.failure == nil)
    }

    @Test func registrationFailuresAreKeyedByPluginId() async throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)
        let good = try #require(viewModel.install(name: "Good", entryScript: "noteBytez.addCommand('x');", permissions: [.addCommand]))
        let broken = try #require(viewModel.install(name: "Broken", entryScript: "throw new Error('boom');", permissions: [.addCommand]))

        let failures = await viewModel.registrationFailures()

        #expect(failures[good.id] == nil)
        #expect(failures[broken.id]?.contains("boom") == true)
    }

    @Test func invokingAPluginCommandRunsItOnTheOpenDocument() async throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Notes", content: "Existing line", libraryId: libraryId, in: context)
        let documentViewModel = DocumentViewModel(document: document, modelContext: context)
        let viewModel = PluginViewModel(libraryId: libraryId, modelContext: context)
        let plugin = try #require(viewModel.install(
            name: "Hello",
            entryScript: "if (noteBytez.invokedCommand === 'Say Hello') { noteBytez.appendToCurrentNote('Hello'); }",
            permissions: [.writeCurrentNote]
        ))
        let command = PluginCommand(pluginId: plugin.id, pluginName: "Hello", commandName: "Say Hello")

        let result = await viewModel.invokeCommand(command, documentViewModel: documentViewModel)

        #expect(result == .finished)
        #expect(documentViewModel.content.contains("Hello"))
    }

    @Test func invokingACommandOfAnUninstalledPluginIsAScriptError() async throws {
        let context = try makeContext()
        let viewModel = PluginViewModel(libraryId: UUID(), modelContext: context)
        let command = PluginCommand(pluginId: UUID(), pluginName: "Gone", commandName: "Run")

        let result = await viewModel.invokeCommand(command, documentViewModel: nil)

        guard case .scriptError = result else {
            Issue.record("Expected .scriptError for an unknown plugin")
            return
        }
    }

    @Test func failureDescriptionNamesThePluginAndTheProblem() {
        #expect(PluginViewModel.failureDescription(for: .finished, pluginName: "Mine") == nil)
        #expect(PluginViewModel.failureDescription(for: .scriptError("boom"), pluginName: "Mine")?.contains("boom") == true)
        #expect(PluginViewModel.failureDescription(for: .scriptError("boom"), pluginName: "Mine")?.contains("Mine") == true)
        let timeout = PluginViewModel.failureDescription(for: .timedOut, pluginName: "Mine")
        #expect(timeout?.contains("Mine") == true)
        #expect(timeout?.contains("2 seconds") == true)
    }

}
