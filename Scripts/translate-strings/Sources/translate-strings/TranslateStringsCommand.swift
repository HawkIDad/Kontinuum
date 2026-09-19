// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  main.swift
//  translate-strings
//
//  Phase 0.5 of NoteBytez/Docs/Plans/NoteBytez20260823v2- HOLD -MultiLanguage.md: reads
//  Localizable.xcstrings + Glossary.md, finds keys where a locale's state is new/stale/missing,
//  calls the configured translation model, and writes results back into the .xcstrings — an
//  idempotent, re-runnable, diffable step whose output is committed to git (so a re-run only
//  touches what English changed, acting as translation memory).
//
//  Usage:
//    swift run translate-strings --extract NoteBytez              (Phase 2.2)
//    swift run translate-strings --report [--locale es,fr,de]
//    swift run translate-strings --locale es,fr --dry-run
//    swift run translate-strings --locale es,fr                 (needs ANTHROPIC_API_KEY)
//

import Foundation

/// The 24-locale target set (G8) — used as the `--report` default when no `--locale` is given,
/// and as the accepted vocabulary for `--locale`.
let allTargetLocales = [
    "en-GB", "es", "fr", "de", "it", "pt-BR", "nl", "sv", "da", "nb", "fi",
    "pl", "cs", "hu", "ro", "tr", "el", "lt", "sr-Cyrl", "zh-Hans", "ja", "ko", "ar"
]

struct Options {
    var locales: [String]?
    var dryRun = false
    var report = false
    var catalogPath: String?
    var glossaryPath: String?
    var extractPath: String?
}

func parseOptions(_ arguments: [String]) -> Options {
    var options = Options()
    var index = 0
    while index < arguments.count {
        let arg = arguments[index]
        switch arg {
        case "--locale":
            index += 1
            if index < arguments.count {
                options.locales = arguments[index].split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            }
        case "--dry-run":
            options.dryRun = true
        case "--report":
            options.report = true
        case "--catalog":
            index += 1
            if index < arguments.count { options.catalogPath = arguments[index] }
        case "--glossary":
            index += 1
            if index < arguments.count { options.glossaryPath = arguments[index] }
        case "--extract":
            index += 1
            if index < arguments.count { options.extractPath = arguments[index] }
        default:
            FileHandle.standardError.write("Unknown argument: \(arg)\n".data(using: .utf8)!)
        }
        index += 1
    }
    return options
}

/// Repo-relative defaults, resolved from this source file's own on-disk location (`#filePath`)
/// rather than the current working directory — so `swift run` works the same regardless of
/// where it's invoked from.
func defaultRepoPath(_ relativeFromScriptsDir: String) -> URL {
    // This file lives at "<repo>/Scripts/translate-strings/Sources/translate-strings/main.swift".
    let thisFile = URL(fileURLWithPath: #filePath)
    let repoRoot = thisFile
        .deletingLastPathComponent() // translate-strings/
        .deletingLastPathComponent() // Sources/
        .deletingLastPathComponent() // translate-strings/ (package root)
        .deletingLastPathComponent() // Scripts/
        .deletingLastPathComponent() // <repo>
    return repoRoot.appendingPathComponent(relativeFromScriptsDir)
}

@main
struct TranslateStrings {

    static func main() async {
        let options = parseOptions(Array(CommandLine.arguments.dropFirst()))
        let catalogURL = options.catalogPath.map { URL(fileURLWithPath: $0) } ?? defaultRepoPath("NoteBytez/Localizable.xcstrings")
        let glossaryURL = options.glossaryPath.map { URL(fileURLWithPath: $0) } ?? defaultRepoPath("NoteBytez/Docs/Localization/Glossary.md")

        do {
            var catalog = try StringCatalog.load(from: catalogURL)
            let glossary = try Glossary.load(from: glossaryURL)
            print("Loaded \(catalog.entries.count) key(s) from \(catalogURL.lastPathComponent), \(glossary.terms.count) glossary term(s).")

            if let extractPath = options.extractPath {
                let root = URL(fileURLWithPath: extractPath, isDirectory: true)
                var addedCount = 0
                var skippedCount = 0
                for file in StringExtractor.swiftFiles(under: root).sorted(by: { $0.path < $1.path }) {
                    guard let source = try? String(contentsOf: file, encoding: .utf8) else { continue }
                    for found in StringExtractor.extract(from: source, fileName: file.path) {
                        let existedBefore = catalog.entries.contains { $0.key == found.key }
                        catalog.ensureKeyExists(found.key, comment: found.comment)
                        if existedBefore { skippedCount += 1 } else { addedCount += 1 }
                    }
                }
                if options.dryRun {
                    print("--dry-run: would add \(addedCount) new key(s) (\(skippedCount) already present). No file written.")
                } else {
                    try catalog.write()
                    print("Extraction complete: added \(addedCount) new key(s), \(skippedCount) already present. Wrote \(catalogURL.path).")
                }
                return
            }

            if options.report {
                let locales = options.locales ?? allTargetLocales
                print("\n--- Drift report (\(locales.count) locale(s)) ---")
                DriftReport.printReport(DriftReport.generate(catalog: catalog, locales: locales))
                if options.locales == nil { return } // `--report` alone: report only, no translation
            }

            guard let requestedLocales = options.locales else {
                if !options.report {
                    print("Nothing to do — pass --locale <a,b,c> to translate, or --report for a drift report.")
                }
                return
            }

            let translator: Translator
            if options.dryRun {
                translator = DryRunTranslator()
                print("--dry-run: no network calls, no file writes.")
            } else if let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !apiKey.isEmpty {
                translator = AnthropicTranslator(apiKey: apiKey)
            } else {
                print("ANTHROPIC_API_KEY not set — falling back to a dry run (no translations will be written).")
                translator = DryRunTranslator()
            }

            let blockedKeys = catalog.entries.filter(\.needsContext).map(\.key)
            if !blockedKeys.isEmpty {
                print("\n--- Blocked — flagged NEEDS-CONTEXT (\(blockedKeys.count)) ---")
                for key in blockedKeys.sorted() { print("  \(key)") }
                print("Add a real comment to each before translating. Exiting without translating anything.")
                exit(1)
            }

            var mismatches: [Placeholders.Mismatch] = []
            var translatedCount = 0

            for locale in requestedLocales {
                for entry in catalog.entries where !entry.isPluralVariant {
                    let state = entry.state(for: locale)
                    guard state == nil || state == "new" || state == "needs_review" || state == "stale" else { continue }

                    let request = TranslationRequest(
                        sourceText: entry.sourceText,
                        comment: entry.comment,
                        glossaryHits: glossary.hits(in: entry.sourceText + " " + (entry.comment ?? "")),
                        targetLocale: locale
                    )

                    do {
                        let translated = try await translator.translate(request)
                        guard Placeholders.isSafe(source: entry.sourceText, translated: translated) || options.dryRun else {
                            mismatches.append(Placeholders.Mismatch(
                                key: entry.key, locale: locale,
                                sourceTokens: Placeholders.tokens(in: entry.sourceText),
                                translatedTokens: Placeholders.tokens(in: translated)
                            ))
                            continue
                        }
                        var updated = entry
                        updated.setTranslation(translated, locale: locale)
                        if !options.dryRun {
                            catalog.upsert(updated)
                        }
                        translatedCount += 1
                        print("  [\(locale)] \(entry.key) -> \(translated)")
                    } catch {
                        FileHandle.standardError.write("  [\(locale)] \(entry.key): translation failed — \(error)\n".data(using: .utf8)!)
                    }
                }
            }

            if !mismatches.isEmpty {
                print("\n--- Placeholder-safety failures (\(mismatches.count)) ---")
                for mismatch in mismatches { print(mismatch) }
                exit(1)
            }

            if options.dryRun {
                print("\nDry run complete — \(translatedCount) key(s) would be translated. No file written.")
            } else {
                try catalog.write()
                print("\nWrote \(translatedCount) translation(s) to \(catalogURL.path).")
            }
        } catch {
            FileHandle.standardError.write("Error: \(error)\n".data(using: .utf8)!)
            exit(1)
        }
    }

}
