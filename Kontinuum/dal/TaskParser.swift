// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  TaskParser.swift
//  Kontinuum
//

import Foundation

/// `- [ ]`/`- [x]` checkbox line detection and toggling, tied to a `Block`'s content via
/// `TaskDAL`. Pure string functions, mirroring `WikilinkParser`/`TagParser`'s split between
/// indexing/editing logic (here) and rendering (each view's line-by-line preview).
enum TaskParser {

    struct TaskMatch: Equatable {
        let isDone: Bool
        let text: String
    }

    private static let taskLinePattern = try! NSRegularExpression(pattern: #"^\s*[-*+]\s+\[([ xX])\]\s+(.*)$"#)

    /// Whether `line` is a checkbox line, and if so its state/text. `nil` for any other line,
    /// including a plain (non-checkbox) list item.
    static func match(in line: String) -> TaskMatch? {
        let nsLine = line as NSString
        guard let match = taskLinePattern.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else {
            return nil
        }
        let marker = nsLine.substring(with: match.range(at: 1))
        let text = nsLine.substring(with: match.range(at: 2))
        return TaskMatch(isDone: marker.lowercased() == "x", text: text)
    }

    /// Every checkbox line in `content`, in document order.
    static func extractTasks(from content: String) -> [TaskMatch] {
        content.components(separatedBy: "\n").compactMap { match(in: $0) }
    }

    /// Flips the Nth (0-based, document order) checkbox line's marker. No-op if `taskIndex`
    /// is out of range.
    static func toggling(taskIndex: Int, in content: String) -> String {
        guard taskIndex >= 0 else { return content }

        var lines = content.components(separatedBy: "\n")
        var currentIndex = 0
        for (lineIndex, line) in lines.enumerated() {
            guard match(in: line) != nil else { continue }
            if currentIndex == taskIndex {
                lines[lineIndex] = togglingMarker(in: line)
                break
            }
            currentIndex += 1
        }
        return lines.joined(separator: "\n")
    }

    private static func togglingMarker(in line: String) -> String {
        let nsLine = line as NSString
        guard let match = taskLinePattern.firstMatch(in: line, range: NSRange(location: 0, length: nsLine.length)) else {
            return line
        }
        let markerRange = match.range(at: 1)
        let currentMarker = nsLine.substring(with: markerRange)
        let newMarker = currentMarker.lowercased() == "x" ? " " : "x"
        let mutable = NSMutableString(string: line)
        mutable.replaceCharacters(in: markerRange, with: newMarker)
        return mutable as String
    }

}
