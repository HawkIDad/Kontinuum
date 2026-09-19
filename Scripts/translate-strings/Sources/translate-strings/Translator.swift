// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  Translator.swift
//  translate-strings
//

import Foundation

struct TranslationRequest {
    let sourceText: String
    let comment: String?
    let glossaryHits: [Glossary.Term]
    let targetLocale: String
}

protocol Translator {
    func translate(_ request: TranslationRequest) async throws -> String
}

/// Used for `--dry-run` and for any locale run without `ANTHROPIC_API_KEY` set — makes no
/// network call, so the rest of the pipeline (drift report, placeholder validation, catalog
/// read/write) is fully exercisable and testable without live credentials or cost. Returns the
/// source text unchanged with a marker prefix, so a dry run's console/report output is
/// obviously *not* a real translation rather than silently looking like one.
struct DryRunTranslator: Translator {
    func translate(_ request: TranslationRequest) async throws -> String {
        "[dry-run:\(request.targetLocale)] \(request.sourceText)"
    }
}

/// Calls Anthropic's Messages API. Requires `ANTHROPIC_API_KEY` in the environment — with no
/// key set, `translate-strings` falls back to `DryRunTranslator` and says so, rather than
/// failing the whole run.
///
/// NOTE: this implementation has not been exercised against a live API key as part of building
/// it — no credential was available in the environment this was written in. The request shape
/// (model, endpoint, headers, response parsing) is believed correct as of this writing; treat
/// the first real `--locale` run as this code's actual integration test, not something already
/// proven to work end-to-end.
struct AnthropicTranslator: Translator {

    let apiKey: String
    /// Per this workspace's own guidance: default to the latest, most capable model for new
    /// integrations.
    var model = "claude-sonnet-5"

    func translate(_ request: TranslationRequest) async throws -> String {
        let url = URLComponents(string: "https://api.anthropic.com/v1/messages")!
        var httpRequest = URLRequest(url: url.url!)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        httpRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": Self.systemPrompt,
            "messages": [["role": "user", "content": Self.userPrompt(for: request)]]
        ]
        httpRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: httpRequest)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let bodyText = String(data: data, encoding: .utf8) ?? "<non-UTF8 body>"
            throw TranslatorError.httpError(status: (response as? HTTPURLResponse)?.statusCode ?? -1, body: bodyText)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw TranslatorError.unexpectedResponseShape
        }
        // Guard against the model wrapping its answer in explanation or quotes despite the
        // system prompt's instruction — take the last non-empty line as the translation.
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true)
        return (lines.last.map(String.init) ?? text).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let systemPrompt = """
    You translate short UI strings for a Markdown note-taking app, NoteBytez. Reply with ONLY \
    the translated string on its own line — no quotes, no explanation, no alternatives. \
    Preserve every placeholder token exactly as written (things like %@, %1$@, %lld, %#@count@) \
    in the same form, and preserve leading/trailing whitespace and punctuation style \
    conventions of the target language. If a "Glossary" section is given, follow its directive \
    for each named term exactly: "loanword" means keep that exact English word unchanged; \
    "transliterate" means render the English word's sound in the target script; "translate" \
    means use the target language's own word for the concept.
    """

    private static func userPrompt(for request: TranslationRequest) -> String {
        var prompt = "Target language: \(request.targetLocale)\nSource (en-US): \(request.sourceText)"
        if let comment = request.comment, !comment.isEmpty {
            prompt += "\nContext: \(comment)"
        }
        if !request.glossaryHits.isEmpty {
            prompt += "\nGlossary:\n"
            for term in request.glossaryHits {
                prompt += "- \(term.name): \(term.usageNote)\n"
            }
        }
        return prompt
    }

    enum TranslatorError: Error, CustomStringConvertible {
        case httpError(status: Int, body: String)
        case unexpectedResponseShape

        var description: String {
            switch self {
            case .httpError(let status, let body): return "Anthropic API returned HTTP \(status): \(body.prefix(500))"
            case .unexpectedResponseShape: return "Anthropic API response did not match the expected shape."
            }
        }
    }

}
