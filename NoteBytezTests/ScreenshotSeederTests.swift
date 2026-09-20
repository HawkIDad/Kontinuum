// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ScreenshotSeederTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

/// The DEBUG-only seed library used by the website screenshot pipeline
/// (WebSite20260919v1-WebSite.md Phase W4).
struct ScreenshotSeederTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self,
            DocumentNotebook.self, TaskItem.self, Property.self, DocumentProperty.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    private func makeFixtureFolder(files: [String: String]) throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, content) in files {
            try content.write(to: folder.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        return folder
    }

    @Test func seedingImportsEveryMarkdownFileIntoANewSelectedLibrary() throws {
        let context = try makeContext()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let folder = try makeFixtureFolder(files: [
            "Alpha.md": "Links to [[Beta]] #demo",
            "Beta.md": "- [ ] A task",
        ])

        let libraryId = try #require(ScreenshotSeeder.seed(folderURL: folder, in: context, defaults: defaults))

        let documents = try context.fetch(FetchDescriptor<Document>())
        #expect(documents.count == 2)
        #expect(documents.allSatisfy { $0.libraryId == libraryId })
        #expect(LibraryDAL.selectedLibraryId(in: defaults) == libraryId)
    }

    @Test func seedingAMissingFolderReturnsNilAndCreatesNothing() throws {
        let context = try makeContext()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        #expect(ScreenshotSeeder.seed(folderURL: missing, in: context, defaults: defaults) == nil)
        #expect(try context.fetch(FetchDescriptor<Library>()).isEmpty)
    }

    @Test func seedingIsDeterministicAcrossRuns() throws {
        let folder = try makeFixtureFolder(files: ["Note.md": "Body #tag"])
        let firstContext = try makeContext()
        let secondContext = try makeContext()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))

        _ = ScreenshotSeeder.seed(folderURL: folder, in: firstContext, defaults: defaults)
        _ = ScreenshotSeeder.seed(folderURL: folder, in: secondContext, defaults: defaults)

        let firstTitles = try firstContext.fetch(FetchDescriptor<Document>()).compactMap(\.title).sorted()
        let secondTitles = try secondContext.fetch(FetchDescriptor<Document>()).compactMap(\.title).sorted()
        #expect(firstTitles == secondTitles)
    }

    @Test func destinationParsesAKnownRawValueAndRejectsUnknownOnes() {
        #expect(ScreenshotSeeder.destination(named: "Tags") == .tags)
        #expect(ScreenshotSeeder.destination(named: "Saved Views") == .savedViews)
        #expect(ScreenshotSeeder.destination(named: "Nope") == nil)
        #expect(ScreenshotSeeder.destination(named: nil) == nil)
    }

    @Test func settingPrefersTheEnvironmentOverUserDefaults() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        defaults.set("fromDefaults", forKey: "Key")

        #expect(ScreenshotSeeder.setting("Key", environment: ["Key": "fromEnvironment"], defaults: defaults) == "fromEnvironment")
        #expect(ScreenshotSeeder.setting("Key", environment: [:], defaults: defaults) == "fromDefaults")
        #expect(ScreenshotSeeder.setting("Missing", environment: [:], defaults: defaults) == nil)
    }

    @Test func appearanceParsesLightAndDarkOnly() {
        #expect(ScreenshotSeeder.Appearance(name: "dark") == .dark)
        #expect(ScreenshotSeeder.Appearance(name: "light") == .light)
        #expect(ScreenshotSeeder.Appearance(name: "sepia") == nil)
        #expect(ScreenshotSeeder.Appearance(name: nil) == nil)
    }

    @Test func seedingFromNotesJSONImportsEachNoteAndRejectsMalformedJSON() throws {
        let context = try makeContext()
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))

        #expect(ScreenshotSeeder.seed(notesJSON: "not json", in: context, defaults: defaults) == nil)

        let json = #"{"Alpha.md":"Links to [[Beta]]","Beta.md":"- [ ] A task"}"#
        let libraryId = try #require(ScreenshotSeeder.seed(notesJSON: json, in: context, defaults: defaults))

        let documents = try context.fetch(FetchDescriptor<Document>())
        #expect(documents.compactMap(\.title).sorted() == ["Alpha", "Beta"])
        #expect(documents.allSatisfy { $0.libraryId == libraryId })
    }
}
