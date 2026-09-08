// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationFormatDetector.swift
//  Kontinuum
//

import Foundation

/// Which external PKM tool a vault came from — the Migration Assistant's (S23) first question,
/// per Journey 9 ("distinct from MVP's generic Import — this one asks which tool the vault came
/// from first").
enum MigrationSourceFormat: String, CaseIterable, Identifiable {
    case obsidian
    case logseq

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .obsidian: return "Obsidian"
        case .logseq: return "Logseq"
        }
    }
}

/// Auto-detects a vault's source tool from its own marker folder — an Obsidian vault always has
/// a `.obsidian/` config folder at its root; a Logseq graph always has a `logseq/` one. `nil`
/// means neither marker was found (an ambiguous or non-vault folder) — the Migration Assistant
/// falls back to asking the user directly rather than guessing.
enum MigrationFormatDetector {

    private static let obsidianMarker = ".obsidian"
    private static let logseqMarker = "logseq"

    static func detect(folderURL: URL, fileManager: FileManager = .default) -> MigrationSourceFormat? {
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { folderURL.stopAccessingSecurityScopedResource() } }

        var isDirectory: ObjCBool = false

        let obsidianPath = folderURL.appendingPathComponent(obsidianMarker).path
        if fileManager.fileExists(atPath: obsidianPath, isDirectory: &isDirectory), isDirectory.boolValue {
            return .obsidian
        }

        let logseqPath = folderURL.appendingPathComponent(logseqMarker).path
        if fileManager.fileExists(atPath: logseqPath, isDirectory: &isDirectory), isDirectory.boolValue {
            return .logseq
        }

        return nil
    }

}
