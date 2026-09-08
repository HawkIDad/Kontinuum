// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphInsightsThresholdStoreTests.swift
//  NoteBytezTests
//

import Testing
import Foundation
@testable import NoteBytez

struct GraphInsightsThresholdStoreTests {

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "GraphInsightsThresholdStoreTests-\(UUID().uuidString)")!
        defaults.removePersistentDomain(forName: defaults.description)
        return defaults
    }

    @Test func defaultsToNinetyDaysWhenNothingIsStored() {
        let defaults = makeDefaults()
        #expect(GraphInsightsThresholdStore.currentThresholdDays(in: defaults) == 90)
    }

    @Test func setCurrentThresholdDaysRoundTrips() {
        let defaults = makeDefaults()
        GraphInsightsThresholdStore.setCurrentThresholdDays(30, in: defaults)
        #expect(GraphInsightsThresholdStore.currentThresholdDays(in: defaults) == 30)
    }

}
