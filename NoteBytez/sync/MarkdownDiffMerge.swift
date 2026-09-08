// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MarkdownDiffMerge.swift
//  NoteBytez
//

import Foundation

/// One line-diff hunk between an "old" (server) and "new" (client) version of a Markdown
/// document. `.unchanged` hunks have no decision to make; `.changed` hunks are what
/// `DiffMergeView` renders as an old|new pair with a per-hunk accept toggle.
struct DiffHunk: Identifiable {

    nonisolated enum Kind {
        case unchanged
        case changed
    }

    let id = UUID()
    let removedLines: [String]
    let addedLines: [String]
    let unchangedLines: [String]

    var kind: Kind { unchangedLines.isEmpty ? .changed : .unchanged }

}

/// A from-scratch, line-based LCS diff — "diff-match-patch style" in spirit (hunks with
/// accept/reject), not a port of Google's character-level library, which would be a lot of
/// machinery for Markdown notes that are naturally line-oriented (bullets, paragraphs).
enum MarkdownDiffMerge {

    private enum LineOp {
        case equal(String)
        case removed(String)
        case added(String)
    }

    static func hunks(old: String, new: String) -> [DiffHunk] {
        groupIntoHunks(diffOps(oldLines: old.components(separatedBy: "\n"), newLines: new.components(separatedBy: "\n")))
    }

    /// `acceptedHunkIDs` marks which `.changed` hunks keep the "new" (client) side — an
    /// unmarked changed hunk keeps the "old" (server) side instead. `.unchanged` hunks are
    /// always included.
    static func merge(hunks: [DiffHunk], acceptedHunkIDs: Set<UUID>) -> String {
        var lines: [String] = []
        for hunk in hunks {
            switch hunk.kind {
            case .unchanged:
                lines.append(contentsOf: hunk.unchangedLines)
            case .changed:
                lines.append(contentsOf: acceptedHunkIDs.contains(hunk.id) ? hunk.addedLines : hunk.removedLines)
            }
        }
        return lines.joined(separator: "\n")
    }

    /// Classic LCS backtrack — O(n·m), fine at journal/note-sized text.
    private static func diffOps(oldLines: [String], newLines: [String]) -> [LineOp] {
        let m = oldLines.count
        let n = newLines.count
        guard m > 0 || n > 0 else { return [] }

        var table = [[Int]](repeating: [Int](repeating: 0, count: n + 1), count: m + 1)
        for i in stride(from: m - 1, through: 0, by: -1) {
            for j in stride(from: n - 1, through: 0, by: -1) {
                table[i][j] = oldLines[i] == newLines[j] ? table[i + 1][j + 1] + 1 : max(table[i + 1][j], table[i][j + 1])
            }
        }

        var ops: [LineOp] = []
        var i = 0
        var j = 0
        while i < m && j < n {
            if oldLines[i] == newLines[j] {
                ops.append(.equal(oldLines[i]))
                i += 1
                j += 1
            } else if table[i + 1][j] >= table[i][j + 1] {
                ops.append(.removed(oldLines[i]))
                i += 1
            } else {
                ops.append(.added(newLines[j]))
                j += 1
            }
        }
        while i < m {
            ops.append(.removed(oldLines[i]))
            i += 1
        }
        while j < n {
            ops.append(.added(newLines[j]))
            j += 1
        }
        return ops
    }

    private static func groupIntoHunks(_ ops: [LineOp]) -> [DiffHunk] {
        func isEqualOp(_ op: LineOp) -> Bool {
            if case .equal = op { return true }
            return false
        }

        var hunks: [DiffHunk] = []
        var index = 0
        while index < ops.count {
            if isEqualOp(ops[index]) {
                var lines: [String] = []
                while index < ops.count, case .equal(let line) = ops[index] {
                    lines.append(line)
                    index += 1
                }
                hunks.append(DiffHunk(removedLines: [], addedLines: [], unchangedLines: lines))
            } else {
                var removed: [String] = []
                var added: [String] = []
                while index < ops.count, !isEqualOp(ops[index]) {
                    switch ops[index] {
                    case .removed(let line): removed.append(line)
                    case .added(let line): added.append(line)
                    case .equal: break
                    }
                    index += 1
                }
                hunks.append(DiffHunk(removedLines: removed, addedLines: added, unchangedLines: []))
            }
        }
        return hunks
    }

}
