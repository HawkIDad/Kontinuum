// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MigrationScanner.swift
//  NoteBytez
//

import Foundation

/// One `.canvas` file found by a Migration Assistant scan — carried through to
/// `MigrationDAL.commit` the same "read once, never re-open the source folder" way
/// `ImportFileSummary` already is.
struct MigrationCanvasFileSummary: Identifiable {
    let id = UUID()
    let relativePath: String
    let boardName: String
    let json: String
}

/// The Migration Assistant's (S23) scan-before-commit result — mirrors `ImportScanner`'s
/// "nothing written yet" contract, extended with the format-specific content MVP's plain
/// Markdown-folder import never needed to know about.
struct MigrationScanResult {
    let format: MigrationSourceFormat
    /// Ordinary notes — every Obsidian page, or every non-journal Logseq page (already
    /// transformed by `LogseqImporter`).
    let pages: [ImportFileSummary]
    /// Logseq journal pages, paired with the calendar date parsed from their filename — empty
    /// for Obsidian, which has no equivalent journal-folder convention in this importer's scope.
    let journalPages: [(summary: ImportFileSummary, date: Date)]
    /// Obsidian `.canvas` files — empty for Logseq.
    let canvasFiles: [MigrationCanvasFileSummary]
    /// Original, untranslated `{{query ...}}` text this importer couldn't confidently map —
    /// empty for Obsidian.
    let unsupportedQueries: [String]

    var noteCount: Int { pages.count + journalPages.count }
    var linkCount: Int { pages.reduce(0) { $0 + $1.linkCount } + journalPages.reduce(0) { $0 + $1.summary.linkCount } }
    var taskCount: Int { pages.reduce(0) { $0 + $1.taskCount } + journalPages.reduce(0) { $0 + $1.summary.taskCount } }
    var canvasCount: Int { canvasFiles.count }
    var journalCount: Int { journalPages.count }
    var unsupportedCount: Int { unsupportedQueries.count }
}

/// S23's "scan, then confirm" entry point — one function per source format, sharing
/// `ImportScanner`'s own plain-Markdown scan for the Obsidian case (wikilinks/properties/tasks
/// already round-trip through frontmatter with no format-specific handling needed) and adding
/// exactly the two things each foreign tool needs beyond that: `.canvas` files for Obsidian,
/// `LogseqImporter`-transformed content plus journal separation for Logseq.
enum MigrationScanner {

    static func scan(folderURL: URL, format: MigrationSourceFormat, fileManager: FileManager = .default) -> MigrationScanResult {
        switch format {
        case .obsidian:
            return scanObsidian(folderURL: folderURL, fileManager: fileManager)
        case .logseq:
            return scanLogseq(folderURL: folderURL, fileManager: fileManager)
        }
    }

    private static func scanObsidian(folderURL: URL, fileManager: FileManager) -> MigrationScanResult {
        let pages = ImportScanner.scan(folderURL: folderURL, fileManager: fileManager)
        let canvasFiles = scanCanvasFiles(folderURL: folderURL, fileManager: fileManager)
        return MigrationScanResult(format: .obsidian, pages: pages, journalPages: [], canvasFiles: canvasFiles, unsupportedQueries: [])
    }

    private static func scanCanvasFiles(folderURL: URL, fileManager: FileManager) -> [MigrationCanvasFileSummary] {
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { folderURL.stopAccessingSecurityScopedResource() } }

        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: nil) else { return [] }

        var summaries: [MigrationCanvasFileSummary] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "canvas" else { continue }
            guard let json = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }
            summaries.append(MigrationCanvasFileSummary(
                relativePath: ImportScanner.relativePath(of: fileURL, in: folderURL),
                boardName: fileURL.deletingPathExtension().lastPathComponent,
                json: json
            ))
        }
        return summaries.sorted { $0.relativePath < $1.relativePath }
    }

    /// Its own file walk rather than `ImportScanner.scan` — content must be transformed by
    /// `LogseqImporter` *before* link/task counts are derived (a raw Logseq page's `TODO`/`DONE`
    /// bullets aren't GFM checkboxes yet, so `TaskParser` wouldn't see them), and journal pages
    /// need to be split out from ordinary ones before either is wrapped in an `ImportFileSummary`.
    private static func scanLogseq(folderURL: URL, fileManager: FileManager) -> MigrationScanResult {
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { folderURL.stopAccessingSecurityScopedResource() } }

        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: nil) else {
            return MigrationScanResult(format: .logseq, pages: [], journalPages: [], canvasFiles: [], unsupportedQueries: [])
        }

        var pages: [ImportFileSummary] = []
        var journalPages: [(summary: ImportFileSummary, date: Date)] = []
        var unsupportedQueries: [String] = []

        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "md" else { continue }
            guard let rawContent = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }

            let relativePath = ImportScanner.relativePath(of: fileURL, in: folderURL)
            let transformed = LogseqImporter.transform(rawContent)
            unsupportedQueries.append(contentsOf: transformed.unsupportedQueries)

            let summary = ImportFileSummary(
                relativePath: relativePath,
                title: fileURL.deletingPathExtension().lastPathComponent,
                content: transformed.content,
                linkCount: WikilinkParser.extractTitles(from: transformed.content).count,
                taskCount: TaskParser.extractTasks(from: transformed.content).count,
                notebookNames: []
            )

            if LogseqImporter.isJournalFile(relativePath: relativePath), let date = LogseqImporter.journalDate(forFileNamed: fileURL.lastPathComponent) {
                journalPages.append((summary, date))
            } else {
                pages.append(summary)
            }
        }

        return MigrationScanResult(
            format: .logseq,
            pages: pages.sorted { $0.relativePath < $1.relativePath },
            journalPages: journalPages.sorted { $0.date < $1.date },
            canvasFiles: [],
            unsupportedQueries: unsupportedQueries
        )
    }

}
