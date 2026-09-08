// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationArchiveDAL.swift
//  Kontinuum
//

import Foundation

/// Preserves a migrated vault as a read-only local archive — "nothing about the migration is a
/// one-way door" (Journey 9). Extends `BackupDAL`'s own local-file pattern (Application-Support-
/// rooted, `FileManager`-only, Phase 11's `.completeFileProtection` posture) rather than a new
/// archive mechanism: same directory convention, one sibling folder over from `Backups/`.
enum MigrationArchiveDAL {

    static func archivesDirectory(in fileManager: FileManager = .default) -> URL {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent("MigrationArchives", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Copies `sourceFolderURL`'s entire tree into `MigrationArchives/<libraryId>/<vault name>-
    /// <timestamp>/` — the timestamp suffix means re-running the assistant against the same
    /// vault (or two different vaults with the same folder name) never collides with an earlier
    /// archive. Every copied file gets `.completeFileProtection` plus POSIX read-only
    /// permissions (`0o444`) — the archive is meant to be looked at, not edited; per
    /// `ARCHITECTURE.md`'s no-physical-deletes rule, nothing here is ever deleted by the app
    /// either.
    @discardableResult
    static func archiveOriginalVault(sourceFolderURL: URL, libraryId: UUID, in directory: URL = archivesDirectory(), fileManager: FileManager = .default) throws -> URL {
        let didStartAccessing = sourceFolderURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { sourceFolderURL.stopAccessingSecurityScopedResource() } }

        // The timestamp alone isn't guaranteed unique — two archives of the same vault (or two
        // different vaults sharing a folder name) within the same second would otherwise collide
        // and make `copyItem` throw — so a short random suffix is appended too. The timestamp
        // stays for human readability when browsing `MigrationArchives/` directly; the suffix is
        // what actually guarantees uniqueness.
        let timestamp = archiveTimestampFormatter.string(from: Date())
        let uniqueSuffix = UUID().uuidString.prefix(8)
        let libraryDirectory = directory.appendingPathComponent(libraryId.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: libraryDirectory, withIntermediateDirectories: true)

        let destinationURL = libraryDirectory.appendingPathComponent("\(sourceFolderURL.lastPathComponent)-\(timestamp)-\(uniqueSuffix)", isDirectory: true)
        try fileManager.copyItem(at: sourceFolderURL, to: destinationURL)
        applyReadOnlyProtection(to: destinationURL, fileManager: fileManager)

        return destinationURL
    }

    static func listArchives(libraryId: UUID, in directory: URL = archivesDirectory(), fileManager: FileManager = .default) -> [URL] {
        let libraryDirectory = directory.appendingPathComponent(libraryId.uuidString, isDirectory: true)
        return (try? fileManager.contentsOfDirectory(at: libraryDirectory, includingPropertiesForKeys: nil))?.sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
    }

    /// Best-effort, `try?` throughout: a file whose protection/permissions couldn't be raised is
    /// still a perfectly good archived copy, just not one this method could additionally lock
    /// down — not worth failing the whole archive operation over.
    private static func applyReadOnlyProtection(to rootURL: URL, fileManager: FileManager) {
        guard let enumerator = fileManager.enumerator(at: rootURL, includingPropertiesForKeys: [.isRegularFileKey]) else { return }
        for case let fileURL as URL in enumerator {
            guard (try? fileURL.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true else { continue }
            try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete, .posixPermissions: 0o444], ofItemAtPath: fileURL.path)
        }
    }

    private static let archiveTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

}
