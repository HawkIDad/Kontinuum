// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationViewModel.swift
//  Kontinuum
//

import Foundation
import SwiftData
import Observation

/// Drives S23 (Migration Assistant) for a library that's already been created (optimistically,
/// by the caller) but not yet selected — same "create first, populate or discard on confirm/
/// cancel" contract `ImportViewModel` already establishes for S2.
@Observable
final class MigrationViewModel {

    let library: Library
    private(set) var format: MigrationSourceFormat
    private(set) var scanResult: MigrationScanResult
    /// Whether `format` came from `MigrationFormatDetector` rather than a fallback guess —
    /// drives S23's "It already knows what this is" vs. "Couldn't auto-detect" messaging
    /// (Journey 9).
    private(set) var wasAutoDetected: Bool
    private(set) var archiveError: String?

    private let folderURL: URL
    private let modelContext: ModelContext

    init(library: Library, folderURL: URL, modelContext: ModelContext) {
        self.library = library
        self.folderURL = folderURL
        self.modelContext = modelContext

        let detected = MigrationFormatDetector.detect(folderURL: folderURL)
        let resolvedFormat = detected ?? .obsidian
        self.format = resolvedFormat
        self.wasAutoDetected = detected != nil
        self.scanResult = MigrationScanner.scan(folderURL: folderURL, format: resolvedFormat)
    }

    /// Re-scans against the overridden format — used when the user corrects a wrong (or absent)
    /// auto-detection via S23's format picker.
    func setFormat(_ format: MigrationSourceFormat) {
        guard format != self.format else { return }
        self.format = format
        self.wasAutoDetected = false
        self.scanResult = MigrationScanner.scan(folderURL: folderURL, format: format)
    }

    /// Auto-snapshots before committing anything (`ImportViewModel.confirmImport`'s own
    /// precedent), commits every scanned page/journal/canvas, then archives the original vault.
    /// The archive running last, after the data is already committed, is deliberate: a failed
    /// archive (e.g. disk full) shouldn't discard an otherwise-successful migration —
    /// `archiveError` surfaces the failure without undoing anything.
    func confirmMigration() {
        guard let libraryId = library.libraryId else { return }
        BackupDAL.createSnapshot(cause: .automatic, in: modelContext)
        MigrationDAL.commit(scanResult, libraryId: libraryId, in: modelContext)

        do {
            try MigrationArchiveDAL.archiveOriginalVault(sourceFolderURL: folderURL, libraryId: libraryId)
        } catch {
            archiveError = error.localizedDescription
        }
    }

    func cancelMigration() {
        LibraryDAL.softDelete(library, in: modelContext)
    }

}
