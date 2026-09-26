// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AppCommandTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

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

    // MARK: Plugin commands

    private var wordCount: PluginCommand {
        PluginCommand(pluginId: UUID(), pluginName: "Word Count", commandName: "Insert Word Count")
    }

    @Test func aPluginCommandIsNotPartOfTheStaticAllCasesSet() {
        let command = AppCommand.plugin(wordCount)
        #expect(!AppCommand.allCases.contains { $0.id == command.id })
    }

    @Test func aPluginCommandsTitleIsPluginNameColonCommandName() {
        #expect(AppCommand.plugin(wordCount).title == "Word Count: Insert Word Count")
    }

    @Test func aPluginCommandsIdIsUniquePerPluginAndCommand() {
        let first = PluginCommand(pluginId: UUID(), pluginName: "A", commandName: "Run")
        let second = PluginCommand(pluginId: UUID(), pluginName: "A", commandName: "Run")
        #expect(AppCommand.plugin(first).id != AppCommand.plugin(second).id)
    }

    @Test func aPluginCommandHasANonEmptySystemImageAndFuzzyMatchesItsTitle() {
        let command = AppCommand.plugin(wordCount)
        #expect(!command.systemImage.isEmpty)
        #expect(command.matches(query: "wordcount"))
        #expect(!command.matches(query: "xyz"))
    }

}
