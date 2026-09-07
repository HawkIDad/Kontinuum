// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ConflictStrategyStore.swift
//  Kontinuum
//

import Foundation

/// The three user-selectable conflict resolution strategies — S11's radio choice, and what
/// `SyncEngine` consults the moment a `.serverRecordChanged` conflict is detected to decide
/// whether to auto-resolve it or queue it for S10.
enum ConflictStrategy: String, CaseIterable, Identifiable {

    case keepAllVersions
    case lastWriteWins
    case diffMerge

    var id: String { rawValue }

    var title: String {
        switch self {
        case .keepAllVersions: return "Keep All Versions"
        case .lastWriteWins: return "Last-Write-Wins + Banner"
        case .diffMerge: return "Markdown Diff-Merge"
        }
    }

    var summary: String {
        switch self {
        case .keepAllVersions: return "You resolve every conflict manually."
        case .lastWriteWins: return "Newest edit wins; a banner lets you revert."
        case .diffMerge: return "Auto-merges text; you review the diff."
        }
    }

}

/// UserDefaults-backed, matching `LibraryDAL.selectedLibraryId`'s pattern. Defaults to
/// `.lastWriteWins` — the pre-selected option in `UIUX/05-Wireframes.md`'s S11 mockup.
enum ConflictStrategyStore {

    private static let defaultsKey = "conflictStrategy"

    static func currentStrategy(in defaults: UserDefaults = .standard) -> ConflictStrategy {
        guard let rawValue = defaults.string(forKey: defaultsKey), let strategy = ConflictStrategy(rawValue: rawValue) else {
            return .lastWriteWins
        }
        return strategy
    }

    static func setCurrentStrategy(_ strategy: ConflictStrategy, in defaults: UserDefaults = .standard) {
        defaults.set(strategy.rawValue, forKey: defaultsKey)
    }

}
