// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  StringExtractor.swift
//  translate-strings
//
//  Phase 2.2. Xcode's own "compile-time string extraction" (`SWIFT_EMIT_LOC_STRINGS`) emits
//  per-file `.stringsdata` sidecars during a build, but merging those into the committed
//  `Localizable.xcstrings` turned out — empirically, checked against a real headless build in
//  this environment — to be an Xcode-IDE-only step, not something a plain `xcodebuild build`
//  performs. Rather than depend on that, this is a direct, regex-based sweep of the `.swift`
//  sources themselves: simpler to reason about, testable, and consistent with how
//  `Scripts/lint-hardcoded-strings.sh` and `Scripts/verify-rename.sh` already work in this repo
//  (regex over source text, not a SwiftSyntax-based tool).
//
//  Deliberately conservative: only a handful of well-known SwiftUI initializers, and only a
//  *plain* string-literal argument (no interpolation) — an interpolated literal needs the
//  positional-specifier treatment from Phase 2.4 before it's safe to hand to a translator, so
//  it's left for that pass rather than extracted (and mistranslated) here.

import Foundation

enum StringExtractor {

    struct Found {
        let key: String
        let comment: String?
        let file: String
        let line: Int
    }

    /// One capture group: the literal's contents. Requires no `\(` inside (excludes
    /// interpolation) and no unescaped `"` (handled by requiring the inner content to contain
    /// no bare `"`).
    private static let literalArgumentPatterns: [String] = [
        #"\bText\(\s*"((?:[^"\\]|\\[^(])*)"\s*\)"#,
        #"\bLabel\(\s*"((?:[^"\\]|\\[^(])*)"\s*,"#,
        #"\bButton\(\s*"((?:[^"\\]|\\[^(])*)"\s*[,)]"#,
        #"\.navigationTitle\(\s*"((?:[^"\\]|\\[^(])*)"\s*\)"#,
        #"\.accessibilityLabel\(\s*"((?:[^"\\]|\\[^(])*)"\s*\)"#,
        #"\.help\(\s*"((?:[^"\\]|\\[^(])*)"\s*\)"#,
        #"\bSection\(\s*"((?:[^"\\]|\\[^(])*)"\s*\)"#,
        #"\bString\(localized:\s*"((?:[^"\\]|\\[^(])*)"\s*[,)]"#,
    ]

    private static let compiledPatterns: [NSRegularExpression] = literalArgumentPatterns.map {
        try! NSRegularExpression(pattern: $0)
    }

    /// Scans one file's already-loaded source text. Skips any line containing `\(` inside the
    /// matched quotes implicitly (the capture-group pattern above already excludes it) and any
    /// literal that is empty (a bare `""`, never meaningful UI text).
    static func extract(from source: String, fileName: String) -> [Found] {
        let lines = source.components(separatedBy: "\n")
        var results: [Found] = []

        for (index, line) in lines.enumerated() {
            let nsLine = line as NSString
            let fullRange = NSRange(location: 0, length: nsLine.length)

            for regex in compiledPatterns {
                for match in regex.matches(in: line, range: fullRange) where match.numberOfRanges > 1 {
                    let key = nsLine.substring(with: match.range(at: 1))
                    guard !key.isEmpty else { continue }

                    // A `//` comment on the *previous* non-blank line is the extraction
                    // context (R4) — the same convention a human would read as "what is this
                    // string for."
                    var comment: String?
                    var lookback = index - 1
                    while lookback >= 0, lines[lookback].trimmingCharacters(in: .whitespaces).isEmpty {
                        lookback -= 1
                    }
                    if lookback >= 0 {
                        let candidate = lines[lookback].trimmingCharacters(in: .whitespaces)
                        if candidate.hasPrefix("///") {
                            comment = String(candidate.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                        } else if candidate.hasPrefix("//") {
                            comment = String(candidate.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                        }
                    }

                    results.append(Found(key: key, comment: comment, file: fileName, line: index + 1))
                }
            }
        }
        return results
    }

    /// Recursively finds every `.swift` file under `directory`, excluding any path component
    /// containing "Tests" (this app's own convention: `NoteBytezTests/`, `NoteBytezUITests/`).
    static func swiftFiles(under directory: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil) else { return [] }
        var files: [URL] = []
        for case let url as URL in enumerator {
            guard url.pathExtension == "swift" else { continue }
            guard !url.pathComponents.contains(where: { $0.localizedCaseInsensitiveContains("tests") }) else { continue }
            files.append(url)
        }
        return files
    }

}
