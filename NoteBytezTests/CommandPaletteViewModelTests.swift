// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CommandPaletteViewModelTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct CommandPaletteViewModelTests {

    @Test func emptyQueryReturnsAllCommandsInStableDeclaredOrder() {
        let viewModel = CommandPaletteViewModel(onNavigate: { _ in }, onAction: { _ in })
        #expect(viewModel.results.map(\.id) == AppCommand.allCases.map(\.id))
    }

    @Test func settingAQueryFiltersResults() {
        let viewModel = CommandPaletteViewModel(onNavigate: { _ in }, onAction: { _ in })
        viewModel.query = "graph"
        #expect(viewModel.results.map(\.id) == [AppCommand.navigate(.graph).id])
    }

    @Test func clearingTheQueryBackToEmptyRestoresEveryCommand() {
        let viewModel = CommandPaletteViewModel(onNavigate: { _ in }, onAction: { _ in })
        viewModel.query = "graph"
        viewModel.query = ""
        #expect(viewModel.results.map(\.id) == AppCommand.allCases.map(\.id))
    }

    @Test func selectingANavigationCommandRoutesToTheNavigateCallback() {
        var navigated: AppDestination?
        var acted: AppAction?
        let viewModel = CommandPaletteViewModel(
            onNavigate: { navigated = $0 },
            onAction: { acted = $0 }
        )

        viewModel.select(.navigate(.graph))

        #expect(navigated == .graph)
        #expect(acted == nil)
    }

    @Test func selectingAnActionCommandRoutesToTheActionCallback() {
        var navigated: AppDestination?
        var acted: AppAction?
        let viewModel = CommandPaletteViewModel(
            onNavigate: { navigated = $0 },
            onAction: { acted = $0 }
        )

        viewModel.select(.action(.syncNow))

        #expect(acted == .syncNow)
        #expect(navigated == nil)
    }

    // MARK: Plugin commands

    private let wordCount = PluginCommand(pluginId: UUID(), pluginName: "Word Count", commandName: "Insert Word Count")

    @Test func loadingPluginCommandsAppendsThemAfterTheBuiltIns() async {
        let command = wordCount
        let viewModel = CommandPaletteViewModel(onNavigate: { _ in }, onAction: { _ in }, loadPluginCommands: { [command] })

        await viewModel.loadPluginCommands()

        #expect(viewModel.results.map(\.id) == AppCommand.allCases.map(\.id) + [AppCommand.plugin(command).id])
    }

    @Test func pluginCommandsAreFilteredByTheQuery() async {
        let command = wordCount
        let viewModel = CommandPaletteViewModel(onNavigate: { _ in }, onAction: { _ in }, loadPluginCommands: { [command] })
        await viewModel.loadPluginCommands()

        viewModel.query = "wordcount"

        #expect(viewModel.results.map(\.id) == [AppCommand.plugin(command).id])
    }

    @Test func loadingPluginCommandsKeepsTheCurrentQueryApplied() async {
        let command = wordCount
        let viewModel = CommandPaletteViewModel(onNavigate: { _ in }, onAction: { _ in }, loadPluginCommands: { [command] })
        viewModel.query = "graph"

        await viewModel.loadPluginCommands()

        #expect(viewModel.results.map(\.id) == [AppCommand.navigate(.graph).id])
    }

    @Test func selectingAPluginCommandRoutesToThePluginCallback() {
        var ran: PluginCommand?
        var navigated: AppDestination?
        let viewModel = CommandPaletteViewModel(onNavigate: { navigated = $0 }, onAction: { _ in }, onPluginCommand: { ran = $0 })

        viewModel.select(.plugin(wordCount))

        #expect(ran == wordCount)
        #expect(navigated == nil)
    }

    @Test func withNoLoaderTheResultsAreJustTheBuiltIns() async {
        let viewModel = CommandPaletteViewModel(onNavigate: { _ in }, onAction: { _ in })

        await viewModel.loadPluginCommands()

        #expect(viewModel.results.map(\.id) == AppCommand.allCases.map(\.id))
    }

}
