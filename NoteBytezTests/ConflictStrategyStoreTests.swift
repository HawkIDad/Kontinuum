// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictStrategyStoreTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct ConflictStrategyStoreTests {

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "ConflictStrategyStoreTests-\(UUID().uuidString)")!
        defaults.removePersistentDomain(forName: defaults.description)
        return defaults
    }

    @Test func defaultsToLastWriteWinsWhenNothingIsStored() {
        let defaults = makeDefaults()
        #expect(ConflictStrategyStore.currentStrategy(in: defaults) == .lastWriteWins)
    }

    @Test func setCurrentStrategyRoundTrips() {
        let defaults = makeDefaults()
        ConflictStrategyStore.setCurrentStrategy(.diffMerge, in: defaults)
        #expect(ConflictStrategyStore.currentStrategy(in: defaults) == .diffMerge)
    }

    @Test func settingAStrategyOverwritesThePreviousOne() {
        let defaults = makeDefaults()
        ConflictStrategyStore.setCurrentStrategy(.keepAllVersions, in: defaults)
        ConflictStrategyStore.setCurrentStrategy(.lastWriteWins, in: defaults)
        #expect(ConflictStrategyStore.currentStrategy(in: defaults) == .lastWriteWins)
    }

    @Test func everyStrategyHasADistinctNonEmptyTitleAndSummary() {
        let titles = Set(ConflictStrategy.allCases.map(\.title))
        let summaries = Set(ConflictStrategy.allCases.map(\.summary))
        #expect(titles.count == ConflictStrategy.allCases.count)
        #expect(summaries.count == ConflictStrategy.allCases.count)
        #expect(titles.allSatisfy { !$0.isEmpty })
        #expect(summaries.allSatisfy { !$0.isEmpty })
    }

}
