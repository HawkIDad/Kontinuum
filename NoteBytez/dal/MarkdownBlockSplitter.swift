// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  MarkdownBlockSplitter.swift
//  NoteBytez
//

import Foundation

/// Splits a Document's raw Markdown into block-sized chunks on blank-line boundaries.
/// Fence-aware: a blank line inside a fenced code block (``` or ~~~) never splits it.
enum MarkdownBlockSplitter {

    static func split(_ markdown: String) -> [String] {
        var chunks: [String] = []
        var currentLines: [String] = []
        var isInsideFence = false

        func flushCurrentChunk() {
            let chunk = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !chunk.isEmpty {
                chunks.append(chunk)
            }
            currentLines.removeAll()
        }

        for line in markdown.components(separatedBy: "\n") {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.hasPrefix("```") || trimmedLine.hasPrefix("~~~") {
                isInsideFence.toggle()
                currentLines.append(line)
                continue
            }

            if trimmedLine.isEmpty && !isInsideFence {
                flushCurrentChunk()
            } else {
                currentLines.append(line)
            }
        }
        flushCurrentChunk()

        return chunks
    }

    static func join(_ chunks: [String]) -> String {
        chunks.joined(separator: "\n\n")
    }

    /// Same blank-line/fence-aware splitting as `split(_:)`, but also tracks ATX heading
    /// (`#`..`######`) context: each returned chunk carries the raw titles of the headings
    /// enclosing it, outermost first. A heading line is always its own chunk, whose
    /// `headingPath` is the path as-of *before* that heading is pushed onto the stack — i.e.
    /// its own nesting level, not its content's.
    static func split(withHeadingContext markdown: String) -> [(content: String, headingPath: [String])] {
        var results: [(content: String, headingPath: [String])] = []
        var currentLines: [String] = []
        var isInsideFence = false
        var headingStack: [(level: Int, title: String)] = []

        func flushCurrentChunk() {
            let chunk = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !chunk.isEmpty {
                results.append((content: chunk, headingPath: headingStack.map(\.title)))
            }
            currentLines.removeAll()
        }

        for line in markdown.components(separatedBy: "\n") {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.hasPrefix("```") || trimmedLine.hasPrefix("~~~") {
                isInsideFence.toggle()
                currentLines.append(line)
                continue
            }

            if !isInsideFence, let heading = parseHeading(trimmedLine) {
                flushCurrentChunk()
                while let last = headingStack.last, last.level >= heading.level {
                    headingStack.removeLast()
                }
                results.append((content: trimmedLine, headingPath: headingStack.map(\.title)))
                headingStack.append((level: heading.level, title: heading.title))
                continue
            }

            if trimmedLine.isEmpty && !isInsideFence {
                flushCurrentChunk()
            } else {
                currentLines.append(line)
            }
        }
        flushCurrentChunk()

        return results
    }

    /// An ATX heading line's level and title, or `nil` if `trimmedLine` isn't one. Requires
    /// 1-6 leading `#`s followed by whitespace (or end of line) per CommonMark.
    private static func parseHeading(_ trimmedLine: String) -> (level: Int, title: String)? {
        let characters = Array(trimmedLine)
        var level = 0
        while level < characters.count && characters[level] == "#" {
            level += 1
        }
        guard level >= 1 && level <= 6 else { return nil }

        if level == characters.count {
            return (level, "")
        }
        guard characters[level] == " " || characters[level] == "\t" else { return nil }

        let title = String(characters[(level + 1)...]).trimmingCharacters(in: .whitespaces)
        return (level, title)
    }

}
