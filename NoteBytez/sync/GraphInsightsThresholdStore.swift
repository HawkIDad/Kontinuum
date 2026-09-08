// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphInsightsThresholdStore.swift
//  NoteBytez
//

import Foundation

/// Persists the user-adjustable "stale" threshold (Decision 1, default 90 days) — same
/// `UserDefaults`-backed getter/setter shape as `ConflictStrategyStore`, parameterized on
/// `defaults` for test injection.
enum GraphInsightsThresholdStore {

    private static let defaultsKey = "graphInsightsStaleThresholdDays"
    static let defaultThresholdDays = 90

    static func currentThresholdDays(in defaults: UserDefaults = .standard) -> Int {
        let stored = defaults.integer(forKey: defaultsKey)
        return stored == 0 ? defaultThresholdDays : stored
    }

    static func setCurrentThresholdDays(_ days: Int, in defaults: UserDefaults = .standard) {
        defaults.set(days, forKey: defaultsKey)
    }

}
