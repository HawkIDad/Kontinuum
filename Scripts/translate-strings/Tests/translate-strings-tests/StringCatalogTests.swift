// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  StringCatalogTests.swift
//  translate-strings-tests
//

import Testing
import Foundation
@testable import translate_strings

struct StringCatalogTests {

    private func writeCatalog(_ json: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".xcstrings")
        try json.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private let sampleCatalog = """
    {
      "sourceLanguage" : "en",
      "strings" : {
        "Settings" : {
          "comment" : "Settings row label",
          "localizations" : {
            "es" : { "stringUnit" : { "state" : "translated", "value" : "Configuración" } }
          }
        },
        "Sync Now" : {
          "extractionState" : "manual"
        },
        "%lld note" : {
          "localizations" : {
            "en" : {
              "variations" : {
                "plural" : {
                  "one" : { "stringUnit" : { "state" : "translated", "value" : "%lld note" } },
                  "other" : { "stringUnit" : { "state" : "translated", "value" : "%lld notes" } }
                }
              }
            }
          }
        }
      },
      "version" : "1.0"
    }
    """

    @Test func loadReadsEveryKey() throws {
        let catalog = try StringCatalog.load(from: writeCatalog(sampleCatalog))
        #expect(Set(catalog.entries.map { $0.key }) == ["Settings", "Sync Now", "%lld note"])
    }

    @Test func translatedValueReadsAnExistingLocalization() throws {
        let catalog = try StringCatalog.load(from: writeCatalog(sampleCatalog))
        let settings = try #require(catalog.entries.first { $0.key == "Settings" })
        #expect(settings.translatedValue(for: "es") == "Configuración")
        #expect(settings.translatedValue(for: "fr") == nil)
    }

    @Test func isPluralVariantDetectsTheVariationsShape() throws {
        let catalog = try StringCatalog.load(from: writeCatalog(sampleCatalog))
        let plural = try #require(catalog.entries.first { $0.key == "%lld note" })
        let flat = try #require(catalog.entries.first { $0.key == "Settings" })
        #expect(plural.isPluralVariant)
        #expect(!flat.isPluralVariant)
    }

    @Test func setTranslationThenWriteRoundTrips() throws {
        let url = try writeCatalog(sampleCatalog)
        var catalog = try StringCatalog.load(from: url)
        var entry = try #require(catalog.entries.first { $0.key == "Sync Now" })
        entry.setTranslation("Synchroniser", locale: "fr")
        catalog.upsert(entry)
        try catalog.write()

        let reloaded = try StringCatalog.load(from: url)
        let reloadedEntry = try #require(reloaded.entries.first { $0.key == "Sync Now" })
        #expect(reloadedEntry.translatedValue(for: "fr") == "Synchroniser")
        #expect(reloadedEntry.state(for: "fr") == "translated")
    }

    @Test func ensureKeyExistsIsANoOpForAnExistingKey() throws {
        var catalog = try StringCatalog.load(from: writeCatalog(sampleCatalog))
        let before = catalog.entries.count
        catalog.ensureKeyExists("Settings", comment: "should not overwrite")
        #expect(catalog.entries.count == before)
        #expect(catalog.entries.first { $0.key == "Settings" }?.comment == "Settings row label")
    }

    @Test func ensureKeyExistsAddsANewKey() throws {
        var catalog = try StringCatalog.load(from: writeCatalog(sampleCatalog))
        catalog.ensureKeyExists("Brand New Key", comment: "fresh")
        let added = try #require(catalog.entries.first { $0.key == "Brand New Key" })
        #expect(added.comment == "fresh")
    }

    @Test func needsContextIsFalseForANormalOrCommentlessEntry() throws {
        let catalog = try StringCatalog.load(from: writeCatalog(sampleCatalog))
        let settings = try #require(catalog.entries.first { $0.key == "Settings" })
        let syncNow = try #require(catalog.entries.first { $0.key == "Sync Now" })
        #expect(!settings.needsContext)
        #expect(!syncNow.needsContext)
    }

    @Test func needsContextIsTrueForACommentFlaggedEntry() throws {
        let json = """
        {
          "sourceLanguage" : "en",
          "strings" : {
            "Promote" : {
              "comment" : "NEEDS-CONTEXT: verb or noun? unclear which screen uses this."
            }
          },
          "version" : "1.0"
        }
        """
        let catalog = try StringCatalog.load(from: writeCatalog(json))
        let promote = try #require(catalog.entries.first { $0.key == "Promote" })
        #expect(promote.needsContext)
    }

}
