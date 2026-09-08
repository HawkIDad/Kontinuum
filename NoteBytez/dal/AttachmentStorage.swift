// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AttachmentStorage.swift
//  Kontinuum
//

import Foundation

/// File-system access for attachment bytes — kept separate from `AttachmentDAL` (which owns the
/// `Attachment` metadata row) the same way `BackupDAL` separates its SwiftData work from its own
/// directory helpers. Attachment bytes live in the app's iCloud ubiquity container, not inline
/// in a CloudKit record — private-database record size limits make inlining infeasible at scale.
///
/// Every entry point here takes its container root as an explicit parameter (mirroring
/// `BackupDAL.createSnapshot(..., directory: URL = backupsDirectory())`) so tests can inject a
/// temp directory instead of resolving the real ubiquity container.
enum AttachmentStorage {

    private static let ubiquityContainerIdentifier = "iCloud.com.g9Consulting.Kontinuum"

    /// Root of the app's iCloud ubiquity container, or `nil` if iCloud is unavailable (signed
    /// out, disabled, offline on first launch). Callers surface this as "can't attach files
    /// while iCloud is unavailable," not a crash.
    static func containerRoot(fileManager: FileManager = .default) -> URL? {
        fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)
    }

    /// `AttachmentStore/<documentId>/` — deliberately outside the container's `Documents`
    /// subfolder (the only part Files.app surfaces), since these files are Kontinuum-managed
    /// state a user shouldn't rename/delete out from under the app.
    static func documentDirectory(documentId: UUID, containerRoot: URL, fileManager: FileManager = .default) -> URL {
        let directory = containerRoot.appendingPathComponent("AttachmentStore", isDirectory: true)
            .appendingPathComponent(documentId.uuidString, isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// Copies `sourceURL`'s bytes into the document's attachment directory under
    /// `<attachmentId>-<sanitizedFileName>`, returning the path relative to `containerRoot`
    /// (what `Attachment.relativePath` stores) so it stays valid across a container-root change.
    static func copyIntoContainer(sourceURL: URL, documentId: UUID, attachmentId: UUID, fileName: String, containerRoot: URL, fileManager: FileManager = .default) throws -> String {
        let directory = documentDirectory(documentId: documentId, containerRoot: containerRoot, fileManager: fileManager)
        let sanitizedFileName = sanitize(fileName)
        let destinationURL = directory.appendingPathComponent("\(attachmentId.uuidString)-\(sanitizedFileName)")

        let didStartAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { sourceURL.stopAccessingSecurityScopedResource() } }

        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        // Phase 11 (Security-Local Files): `copyItem` carries over the source file's own
        // protection level (typically none, for a file picked from Files/Photos), not this app's
        // — set explicitly rather than inheriting whatever the source happened to have.
        // `setAttributes` is a best-effort, `try?`: failing to raise protection on an already-
        // successfully-copied file shouldn't fail the whole attach operation.
        try? fileManager.setAttributes([.protectionKey: FileProtectionType.complete], ofItemAtPath: destinationURL.path)

        let rootPath = containerRoot.standardizedFileURL.path
        let destinationPath = destinationURL.standardizedFileURL.path
        guard destinationPath.hasPrefix(rootPath) else { return destinationURL.lastPathComponent }
        var relative = String(destinationPath.dropFirst(rootPath.count))
        if relative.hasPrefix("/") { relative.removeFirst() }
        return relative
    }

    /// Resolves a stored `relativePath` back to an on-disk `URL`.
    static func resolve(relativePath: String, containerRoot: URL) -> URL {
        containerRoot.appendingPathComponent(relativePath)
    }

    /// Whether `url` is fully downloaded locally — an iCloud file evicted to save space needs a
    /// download triggered (`ensureDownloaded`) before it can be read. A file with no ubiquitous
    /// status at all (an ordinary local file, e.g. in tests) is treated as downloaded — that key
    /// only has a value for items actually inside an iCloud-backed container.
    static func isDownloaded(at url: URL, fileManager: FileManager = .default) -> Bool {
        guard let values = try? url.resourceValues(forKeys: [.ubiquitousItemDownloadingStatusKey]),
              let status = values.ubiquitousItemDownloadingStatus else {
            return fileManager.fileExists(atPath: url.path)
        }
        return status == .current
    }

    /// Kicks off an on-demand download for a not-yet-local iCloud file. Fire-and-forget — the
    /// caller re-checks `isDownloaded(at:)` on its own render cycle rather than this API
    /// reporting completion, matching the "no progress bar" scope this feature needs.
    static func ensureDownloaded(url: URL, fileManager: FileManager = .default) {
        try? fileManager.startDownloadingUbiquitousItem(at: url)
    }

    private static func sanitize(_ fileName: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:")
        return fileName.components(separatedBy: invalidCharacters).joined(separator: "_")
    }

}

enum AttachmentStorageError: Error {
    case iCloudUnavailable
}
