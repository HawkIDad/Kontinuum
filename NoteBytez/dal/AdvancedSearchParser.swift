// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  AdvancedSearchParser.swift
//  NoteBytez
//

import Foundation

/// Boolean search query parsing and pure evaluation — AND/OR/NOT, exact phrase, `#tag`, and
/// `/regex/` terms, e.g. `#character AND #act2 NOT #resolved`, per
/// NoteBytez-ReleaseFeatures.md's Version 1 section. A `#tag` term always matches the
/// document's tags regardless of scope; a bare word, `"quoted phrase"`, or `/regex/` term
/// matches against whichever `DefaultScope` the caller selected (content vs. path/title) — the
/// same split MVP's `SearchDAL.searchContent`/`searchByTitle` already established, not a new
/// scope model. Pure/no `ModelContext`, same shape as `TagParser`/`WikilinkParser`.
enum AdvancedSearchParser {

    /// `nonisolated`: pure parse-tree data with no UI/shared-state ties, opted out of this
    /// target's `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` — otherwise its `Equatable`
    /// conformance is itself MainActor-isolated, which test assertions (`#expect(a == b)`,
    /// generated as nonisolated code) can't call into (a warning today, a Swift 6 error).
    nonisolated indirect enum Node: Equatable {
        case and(Node, Node)
        case or(Node, Node)
        case not(Node)
        case tag(String)
        case regex(String)
        case text(String)
    }

    enum DefaultScope {
        case content
        case path
    }

    // MARK: - Parsing

    /// Parses `query` into a `Node`, or `nil` if it's empty or malformed (unbalanced
    /// parentheses, a dangling operator, an unterminated quote/regex). Callers should treat a
    /// `nil` result as "not a valid boolean query" and decide their own fallback — `SearchDAL`
    /// falls back to a plain literal-text match rather than showing no results for a
    /// mistyped quote.
    static func parse(_ query: String) -> Node? {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let tokens = tokenize(trimmed)
        guard !tokens.isEmpty else { return nil }

        var parser = Parser(tokens: tokens)
        guard let node = try? parser.parseExpression(), parser.position == tokens.count else { return nil }
        return node
    }

    // MARK: - Evaluation

    static func matches(_ node: Node, title: String, content: String, tags: Set<String>, defaultScope: DefaultScope) -> Bool {
        switch node {
        case .and(let lhs, let rhs):
            return matches(lhs, title: title, content: content, tags: tags, defaultScope: defaultScope)
                && matches(rhs, title: title, content: content, tags: tags, defaultScope: defaultScope)
        case .or(let lhs, let rhs):
            return matches(lhs, title: title, content: content, tags: tags, defaultScope: defaultScope)
                || matches(rhs, title: title, content: content, tags: tags, defaultScope: defaultScope)
        case .not(let operand):
            return !matches(operand, title: title, content: content, tags: tags, defaultScope: defaultScope)
        case .tag(let name):
            return tags.contains(TagParser.canonicalize(name))
        case .regex(let pattern):
            guard !isPotentiallyCatastrophic(pattern), let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return false }
            switch defaultScope {
            case .path:
                return regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) != nil
            case .content:
                return regex.firstMatch(in: content, range: NSRange(content.startIndex..., in: content)) != nil
                    || regex.firstMatch(in: title, range: NSRange(title.startIndex..., in: title)) != nil
            }
        case .text(let text):
            switch defaultScope {
            case .path:
                return title.localizedCaseInsensitiveContains(text)
            case .content:
                return content.localizedCaseInsensitiveContains(text) || title.localizedCaseInsensitiveContains(text)
            }
        }
    }

    // MARK: - Regex safety

    /// A coarse, deliberately conservative heuristic: rejects a regex containing a quantified
    /// group whose own contents are themselves quantified (e.g. `(a+)+`, `(a*)*`) — the classic
    /// nested-quantifier shape behind most real-world catastrophic-backtracking patterns.
    /// Chosen over a runtime timeout: `NSRegularExpression` matching isn't cancellable once
    /// started, so a timeout would only stop the *caller* from waiting — the runaway match
    /// itself keeps burning a thread in the background, and a live-search-as-you-type UI could
    /// leak one of those per keystroke. Rejecting before ever executing the pattern avoids that
    /// entirely. This is not a general ReDoS detector (that's an open research problem); it
    /// catches the common case cheaply and safely.
    static func isPotentiallyCatastrophic(_ pattern: String) -> Bool {
        guard pattern.count < 500 else { return true }
        let range = NSRange(pattern.startIndex..., in: pattern)
        return catastrophicPatternDetector.firstMatch(in: pattern, range: range) != nil
    }

    private static let catastrophicPatternDetector = try! NSRegularExpression(pattern: #"\([^()]*[+*][^()]*\)[+*]"#)

    // MARK: - Tokenizing

    private enum Token: Equatable {
        case lparen, rparen, and, or, not
        case tag(String)
        case regex(String)
        case text(String)
    }

    private static func tokenize(_ query: String) -> [Token] {
        var tokens: [Token] = []
        let chars = Array(query)
        var i = 0

        while i < chars.count {
            let c = chars[i]
            if c.isWhitespace { i += 1; continue }

            if c == "(" { tokens.append(.lparen); i += 1; continue }
            if c == ")" { tokens.append(.rparen); i += 1; continue }

            if c == "\"" {
                var j = i + 1
                var text = ""
                while j < chars.count, chars[j] != "\"" { text.append(chars[j]); j += 1 }
                tokens.append(.text(text))
                i = j < chars.count ? j + 1 : j
                continue
            }

            if c == "/" {
                var j = i + 1
                var pattern = ""
                while j < chars.count, chars[j] != "/" { pattern.append(chars[j]); j += 1 }
                tokens.append(.regex(pattern))
                i = j < chars.count ? j + 1 : j
                continue
            }

            if c == "#" {
                var j = i + 1
                var name = ""
                while j < chars.count, !chars[j].isWhitespace, chars[j] != "(", chars[j] != ")" { name.append(chars[j]); j += 1 }
                tokens.append(.tag(name))
                i = j
                continue
            }

            var j = i
            var word = ""
            while j < chars.count, !chars[j].isWhitespace, chars[j] != "(", chars[j] != ")" { word.append(chars[j]); j += 1 }
            switch word.uppercased() {
            case "AND": tokens.append(.and)
            case "OR": tokens.append(.or)
            case "NOT": tokens.append(.not)
            default: tokens.append(.text(word))
            }
            i = j
        }

        return tokens
    }

    // MARK: - Recursive-descent parsing (precedence: OR lowest, AND/implicit-AND, NOT highest)

    private struct Parser {
        let tokens: [Token]
        var position = 0

        private var current: Token? { position < tokens.count ? tokens[position] : nil }
        private mutating func advance() { position += 1 }

        mutating func parseExpression() throws -> Node {
            var node = try parseAnd()
            while current == .or {
                advance()
                node = .or(node, try parseAnd())
            }
            return node
        }

        private mutating func parseAnd() throws -> Node {
            var node = try parseNot()
            // Space-separated terms with no explicit operator default to AND, matching how a
            // plain search query already reads ("foo bar" means both, not either).
            while let tok = current, tok != .or, tok != .rparen {
                if tok == .and { advance() }
                node = .and(node, try parseNot())
            }
            return node
        }

        private mutating func parseNot() throws -> Node {
            if current == .not {
                advance()
                return .not(try parseNot())
            }
            return try parsePrimary()
        }

        private mutating func parsePrimary() throws -> Node {
            guard let tok = current else { throw ParseError.unexpectedEnd }
            switch tok {
            case .lparen:
                advance()
                let node = try parseExpression()
                guard current == .rparen else { throw ParseError.unbalancedParentheses }
                advance()
                return node
            case .tag(let name):
                advance()
                return .tag(name)
            case .regex(let pattern):
                advance()
                return .regex(pattern)
            case .text(let text):
                advance()
                return .text(text)
            case .and, .or, .not, .rparen:
                throw ParseError.unexpectedToken
            }
        }
    }

    private enum ParseError: Error {
        case unexpectedEnd
        case unexpectedToken
        case unbalancedParentheses
    }

}
