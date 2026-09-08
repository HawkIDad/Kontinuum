// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ImportScanner.swift
//  NoteBytez
//

import Foundation

/// One `.md` file found by a folder scan — its content is read once here and carried through
/// to `ImportDAL.importFiles`, so committing an import never needs to re-open the
/// (security-scoped, possibly no-longer-accessible) source folder.
struct ImportFileSummary: Identifiable {
    let id = UUID()
    let relativePath: String
    let title: String
    let content: String
    let linkCount: Int
    let taskCount: Int
    let notebookNames: [String]
}

/// S2's "before any commitment" scan — recursively finds every `.md` file under a picked
/// folder and counts wikilinks/tasks per file, without creating anything yet.
enum ImportScanner {

    static func scan(folderURL: URL, fileManager: FileManager = .default) -> [ImportFileSummary] {
        let didStartAccessing = folderURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { folderURL.stopAccessingSecurityScopedResource() } }

        guard let enumerator = fileManager.enumerator(at: folderURL, includingPropertiesForKeys: nil) else {
            return []
        }

        var summaries: [ImportFileSummary] = []
        for case let fileURL as URL in enumerator {
            guard fileURL.pathExtension.lowercased() == "md" else { continue }
            guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { continue }

            summaries.append(ImportFileSummary(
                relativePath: relativePath(of: fileURL, in: folderURL),
                title: fileURL.deletingPathExtension().lastPathComponent,
                content: content,
                linkCount: WikilinkParser.extractTitles(from: content).count,
                taskCount: TaskParser.extractTasks(from: content).count,
                notebookNames: NotebookParser.extractFrontmatterNotebooks(from: content)
            ))
        }

        return summaries.sorted { $0.relativePath < $1.relativePath }
    }

    /// `internal`, not `private` — `MigrationScanner` (Phase 12) reuses this exact
    /// relative-path computation for its own `.canvas`/Logseq `.md` file walks, rather than a
    /// second copy of the same logic.
    static func relativePath(of fileURL: URL, in rootURL: URL) -> String {
        let filePath = fileURL.standardizedFileURL.path
        let rootPath = rootURL.standardizedFileURL.path
        guard filePath.hasPrefix(rootPath) else { return fileURL.lastPathComponent }

        var relative = String(filePath.dropFirst(rootPath.count))
        if relative.hasPrefix("/") { relative.removeFirst() }
        return relative
    }

}
