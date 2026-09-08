// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CommandPaletteViewModelTests.swift
//  NoteBytezTests
//

import Testing
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

}
