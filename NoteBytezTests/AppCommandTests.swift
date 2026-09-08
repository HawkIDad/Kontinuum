// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AppCommandTests.swift
//  KontinuumTests
//

import Testing
@testable import Kontinuum

struct AppCommandTests {

    @Test func allCasesIncludesOneEntryPerDestinationPlusTheFixedActionSet() {
        let commands = AppCommand.allCases

        for destination in AppDestination.allCases {
            #expect(commands.contains { if case .navigate(destination) = $0 { return true }; return false })
        }
        for action in AppAction.allCases {
            #expect(commands.contains { if case .action(action) = $0 { return true }; return false })
        }
        #expect(commands.count == AppDestination.allCases.count + AppAction.allCases.count)
    }

    @Test func matchesFuzzyFiltersByTitle() {
        #expect(AppCommand.navigate(.graph).matches(query: "graph"))
        #expect(!AppCommand.navigate(.graph).matches(query: "xyz"))
    }

    @Test func fuzzyQueryNewnoteTopHitIsNewNoteAction() {
        let ranked = AppCommand.allCases.filter { $0.matches(query: "newnote") }.sorted { $0.title.count < $1.title.count }
        #expect(ranked.first?.id == AppCommand.action(.newNote).id)
    }

    @Test func fuzzyQueryGraphTopHitIsGraphDestination() {
        let ranked = AppCommand.allCases.filter { $0.matches(query: "graph") }.sorted { $0.title.count < $1.title.count }
        #expect(ranked.first?.id == AppCommand.navigate(.graph).id)
    }

    @Test func everyActionHasADistinctIdTitleAndNonEmptySystemImage() {
        let ids = Set(AppAction.allCases.map(\.id))
        let titles = Set(AppAction.allCases.map(\.title))
        #expect(ids.count == AppAction.allCases.count)
        #expect(titles.count == AppAction.allCases.count)
        #expect(AppAction.allCases.allSatisfy { !$0.systemImage.isEmpty })
    }

    @Test func aNavigateCommandsSystemImageMatchesItsDestination() {
        #expect(AppCommand.navigate(.graph).systemImage == AppDestination.graph.systemImage)
    }

    @Test func anActionCommandsSystemImageMatchesItsAction() {
        #expect(AppCommand.action(.syncNow).systemImage == AppAction.syncNow.systemImage)
    }

}
