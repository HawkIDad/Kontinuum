// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TemplateOnboardingStore.swift
//  NoteBytez
//

import Foundation

/// Tracks whether the one-time first-run role picker has been shown. UserDefaults-backed,
/// mirroring `ConflictStrategyStore` / `LibraryDAL.selectedLibraryId`. Per
/// NoteBytez20260824v1-Templates.md Phase 5.
enum TemplateOnboardingStore {

    private static let defaultsKey = "hasCompletedTemplateOnboarding"

    static func hasCompleted(in defaults: UserDefaults = .standard) -> Bool {
        defaults.bool(forKey: defaultsKey)
    }

    static func markCompleted(in defaults: UserDefaults = .standard) {
        defaults.set(true, forKey: defaultsKey)
    }

    static func reset(in defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: defaultsKey)
    }
}
