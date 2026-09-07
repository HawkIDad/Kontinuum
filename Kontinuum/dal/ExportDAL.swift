// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ExportDAL.swift
//  Kontinuum
//

import Foundation
import SwiftData

enum ExportDAL {

    /// Writes `document`'s exportable Markdown (raw content plus any Notebook-membership
    /// frontmatter) to `<directory>/<sanitized title>.md`.
    static func exportDocument(_ document: Document, to directory: URL, in context: ModelContext) throws {
        let filename = sanitizedFilename(for: document.title ?? "Untitled") + ".md"
        let fileURL = directory.appendingPathComponent(filename)
        try exportableContent(for: document, in: context).write(to: fileURL, atomically: true, encoding: .utf8)
    }

    /// Full library export — every active document, as its own `.md` file, in `directory`.
    @discardableResult
    static func exportLibrary(libraryId: UUID, to directory: URL, in context: ModelContext) -> Int {
        let didStartAccessing = directory.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { directory.stopAccessingSecurityScopedResource() } }

        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: context)
        for document in documents {
            try? exportDocument(document, to: directory, in: context)
        }
        return documents.count
    }

    /// Every active library, each into its own sanitized sub-folder of `directory`. Backs the
    /// blocked-state "Export my notes" escape hatch (NoteBytez20260907v1-Security.md G16) — a
    /// lapsed subscriber can always get their data out, read-only, without resubscribing.
    @discardableResult
    static func exportAllActiveLibraries(to directory: URL, in context: ModelContext) -> Int {
        let didStartAccessing = directory.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { directory.stopAccessingSecurityScopedResource() } }

        var exportedCount = 0
        for library in LibraryDAL.fetchActive(in: context) {
            guard let libraryId = library.libraryId else { continue }
            let libraryFolder = directory.appendingPathComponent(
                sanitizedFilename(for: library.name ?? "Library"),
                isDirectory: true
            )
            try? FileManager.default.createDirectory(at: libraryFolder, withIntermediateDirectories: true)

            for document in DocumentDAL.fetchActive(libraryId: libraryId, in: context) {
                guard (try? exportDocument(document, to: libraryFolder, in: context)) != nil else { continue }
                exportedCount += 1
            }
        }
        return exportedCount
    }

    /// `document.content` with Notebook membership woven in for export, so it round-trips
    /// back into Kontinuum (`NotebookParser.extractFrontmatterNotebooks`) and is immediately
    /// usable in Obsidian/Logseq (their native nested-tag support), per
    /// NoteBytez-ReleaseFeatures.md's Markdown import/export section. A document in no
    /// notebooks exports completely unchanged — no empty frontmatter block added.
    ///
    /// The synthetic `#notebook/<kebab-name>` tag is appended to the body rather than folded
    /// into an existing frontmatter `tags:` list: Kontinuum's own tag index already treats
    /// inline and frontmatter tags identically, so this reaches the same result without the
    /// risk of textually rewriting a user-authored `tags:` line.
    static func exportableContent(for document: Document, in context: ModelContext) -> String {
        let rawContent = document.content ?? ""
        guard let documentId = document.documentId else { return rawContent }

        let notebookNames = NotebookDAL.fetchNotebooks(for: documentId, in: context).compactMap { $0.name }
        guard !notebookNames.isEmpty else { return rawContent }

        let (existingFrontmatterLines, body) = splitFrontmatter(rawContent)
        let notebooksLine = "notebooks: [" + notebookNames.map { "\"\($0)\"" }.joined(separator: ", ") + "]"
        let updatedFrontmatterLines = existingFrontmatterLines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("notebooks:") } + [notebooksLine]

        let syntheticTags = notebookNames.map { "#notebook/\(kebabCase($0))" }.joined(separator: " ")
        let updatedBody = body.isEmpty ? syntheticTags : "\(body)\n\n\(syntheticTags)"

        return "---\n" + updatedFrontmatterLines.joined(separator: "\n") + "\n---\n\n" + updatedBody
    }

    /// Markdown filenames can't contain path separators or the other reserved characters
    /// below — a note titled e.g. "Q1/Q2 Planning" would otherwise silently write into a
    /// subdirectory (or fail) instead of producing one flat file. Internal rather than
    /// `private`: `CanvasDAL`'s JSON Canvas export reuses this so a `.note` card's `file` node
    /// path matches the filename a paired full-library export actually produces.
    static func sanitizedFilename(for title: String) -> String {
        let invalidCharacters = CharacterSet(charactersIn: "/\\:*?\"<>|")
        let sanitized = title.components(separatedBy: invalidCharacters).joined(separator: "-")
        return sanitized.isEmpty ? "Untitled" : sanitized
    }

    /// Splits `content` into its frontmatter lines (empty if none) and body. Mirrors
    /// `TagParser`'s block-finding logic exactly, since both need the same `---`-delimited
    /// boundary.
    private static func splitFrontmatter(_ content: String) -> (frontmatterLines: [String], body: String) {
        let lines = content.components(separatedBy: "\n")
        guard let firstLine = lines.first, firstLine.trimmingCharacters(in: .whitespaces) == "---",
              let closingOffset = lines.dropFirst().firstIndex(where: { $0.trimmingCharacters(in: .whitespaces) == "---" }) else {
            return ([], content)
        }
        let frontmatterLines = Array(lines[1..<closingOffset])
        let body = lines[(closingOffset + 1)...].joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return (frontmatterLines, body)
    }

    /// Obsidian/Logseq tags can't contain whitespace — a notebook named "App Onboarding
    /// Revamp" becomes `app-onboarding-revamp`, per NoteBytez-ReleaseFeatures.md's Decisions
    /// Log.
    private static func kebabCase(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: #"\s+"#, with: "-", options: .regularExpression)
    }

}
