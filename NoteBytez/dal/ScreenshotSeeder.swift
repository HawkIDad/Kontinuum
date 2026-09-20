// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ScreenshotSeeder.swift
//  NoteBytez
//

#if DEBUG
import Foundation
import SwiftData
#if os(macOS)
import AppKit
#endif

/// DEBUG-only seam behind the `-SeedScreenshotLibrary <folder>` launch argument: builds a
/// library from a committed folder of fixture `.md` files (`WebSite/tools/screenshots/seedLibrary`)
/// so the website's screenshots regenerate deterministically. Reuses the S2 import path.
enum ScreenshotSeeder {

    static let libraryName = "Screenshot Library"

    /// Returns the new library's id, or `nil` when the folder has no importable notes.
    @discardableResult
    static func seed(folderURL: URL, in context: ModelContext, defaults: UserDefaults = .standard) -> UUID? {
        let summaries = ImportScanner.scan(folderURL: folderURL)
        guard !summaries.isEmpty else { return nil }

        let library = LibraryDAL.create(name: libraryName, locale: Locale(identifier: "en_US"), in: context)
        guard let libraryId = library.libraryId else { return nil }

        ImportDAL.importFiles(summaries, libraryId: libraryId, in: context)
        try? context.save()

        LibraryDAL.setSelectedLibraryId(libraryId, in: defaults)
        TemplateOnboardingStore.markCompleted(in: defaults)
        return libraryId
    }

    /// Seeds from a JSON object of `{ "<file name>.md": "<content>" }`. The sandboxed Mac app cannot
    /// read the repo's fixture folder, so the capture script passes the notes inline instead.
    @discardableResult
    static func seed(notesJSON: String, in context: ModelContext, defaults: UserDefaults = .standard) -> UUID? {
        guard let notes = try? JSONDecoder().decode([String: String].self, from: Data(notesJSON.utf8)) else { return nil }

        let folderURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: folderURL) }
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
        for (fileName, content) in notes {
            try? content.write(to: folderURL.appendingPathComponent(fileName), atomically: true, encoding: .utf8)
        }
        return seed(folderURL: folderURL, in: context, defaults: defaults)
    }

    /// Seeds from whichever launch setting is present; returns whether a library was created.
    static func seedFromSettings(in context: ModelContext) -> Bool {
        if let notesJSON = setting("SeedScreenshotNotes") {
            return seed(notesJSON: notesJSON, in: context) != nil
        }
        guard let folderPath = setting("SeedScreenshotLibrary") else { return false }
        return seed(folderURL: URL(fileURLWithPath: folderPath, isDirectory: true), in: context) != nil
    }

    static func destination(named name: String?) -> AppDestination? {
        name.flatMap(AppDestination.init(rawValue:))
    }

    /// Navigates once the shell has mounted; the launch arg `-ScreenshotDestination <AppDestination raw value>`.
    static func scheduleNavigation(to destination: AppDestination, afterSeconds delay: TimeInterval = 2) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            NotificationCenter.default.post(name: .noteBytezNavigate, object: destination)
        }
    }

    /// A launch setting. The environment wins: on macOS a `-Key value` launch-argument pair makes
    /// AppKit treat `value` as a file to open, which suppresses the main window, so the capture
    /// script passes settings as environment variables there.
    static func setting(_ key: String, environment: [String: String] = ProcessInfo.processInfo.environment, defaults: UserDefaults = .standard) -> String? {
        environment[key] ?? defaults.string(forKey: key)
    }

    enum Appearance: String {
        case light, dark

        init?(name: String?) {
            guard let name, let appearance = Appearance(rawValue: name) else { return nil }
            self = appearance
        }
    }

    /// macOS only: iOS appearance is switched by the capture script via `simctl ui`.
    static func apply(_ appearance: Appearance) {
#if os(macOS)
        DispatchQueue.main.async {
            NSApplication.shared.appearance = NSAppearance(named: appearance == .dark ? .darkAqua : .aqua)
        }
#endif
    }

}
#endif
