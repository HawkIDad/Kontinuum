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

}
