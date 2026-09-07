// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  KontinuumApp.swift
//  Kontinuum
//
//  Created by David Collison on 8/13/26.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct KontinuumApp: App {

#if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    var sharedModelContainer: ModelContainer

    init() {

        let schema = Schema([
            Library.self,
            Document.self,
            Block.self,
            Tag.self,
            DocumentTag.self,
            Notebook.self,
            DocumentNotebook.self,
            TaskItem.self,
            Property.self,
            DocumentProperty.self,
            TemplateGroup.self,
            NoteTemplate.self,
            NotebookTemplateGroup.self,
            JournalTemplateGroup.self,
            SavedView.self,
            Attachment.self,
            CanvasBoard.self,
            CanvasCard.self,
            CanvasConnector.self,
            Plugin.self
        ])

        // CloudKit sync is handled manually by `SyncEngine` (a `CKSyncEngine` wrapper) rather
        // than SwiftData's own `cloudKitDatabase:` option — that automatic path never exposes
        // individual record events or both sides of a conflict to app code, which Phase 13's
        // sync log and Phase 14's conflict strategies both need. This store is local-only.
        //
        // `-EnableLiveSync` opts a Debug build into the same persistent-store + SyncEngine
        // behavior as Release, for the UI test plan's manual two-account live sync test only
        // (NoteBytez20260823v1-UITests.md Phase 4) — every other Debug launch, including the
        // automated XCUITest suite, stays in-memory and never touches CloudKit.
        let isLiveSyncTestingEnabled = ProcessInfo.processInfo.arguments.contains("-EnableLiveSync")

        // `cloudKitDatabase: .none` is required, not cosmetic: `ModelConfiguration` defaults this
        // to `.automatic`, which silently stands up `NSPersistentCloudKitContainer` mirroring of
        // the whole store whenever the iCloud entitlement is present — a second, uncoordinated
        // sync path racing the manual `SyncEngine` above. Only `SyncEngine` should touch CloudKit.
#if DEBUG
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: !isLiveSyncTestingEnabled, cloudKitDatabase: .none)
#else
        let modelConfiguration = ModelConfiguration(isStoredInMemoryOnly: false, cloudKitDatabase: .none)
#endif

        do {
            self.sharedModelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        // Debug builds use an in-memory store that resets every launch, and shouldn't write
        // test data into the real private CloudKit container — only Release starts the engine,
        // unless `-EnableLiveSync` explicitly opted this Debug launch in.
#if !DEBUG
        SyncEngine.shared.start(modelContainer: self.sharedModelContainer)
#else
        if isLiveSyncTestingEnabled {
            SyncEngine.shared.start(modelContainer: self.sharedModelContainer)
        }

        // `-SeedTestConflict` queues a synthetic Document conflict into `ConflictStore.shared`
        // at launch, so the UI test suite can drive S9/S10 (and Journey 3/8's downstream
        // conflict-resolution UI) without a live CloudKit `.serverRecordChanged` error — the
        // same test-only, DEBUG-gated seam `-EnableLiveSync` establishes above. Mirrors the
        // fixture in `KontinuumTests/JourneyIntegrationTests.swift`'s
        // `journeyThreeConflictDetectedThroughEachStrategyToResolved`. Resolving it through the
        // UI still no-ops (no live `CKSyncEngine` to save against without `-EnableLiveSync` too)
        // — this seam only unblocks reaching and rendering the conflict UI itself.
        if ProcessInfo.processInfo.arguments.contains("-SeedTestConflict") {
            let syncId = UUID()
            let libraryId = UUID()
            let zoneID = CKRecordZone.ID.library(libraryId)
            let recordID = CKRecord.ID.record(syncId: syncId, zoneID: zoneID)

            let client = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
            client["title"] = "Flight Notes"
            client["content"] = "Wrote this on the plane."
            client["updatedOn"] = Date(timeIntervalSince1970: 2000)

            let server = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
            server["title"] = "Flight Notes"
            server["content"] = "Wrote this on the Mac."
            server["updatedOn"] = Date(timeIntervalSince1970: 1000)

            ConflictStore.shared.queue(Conflict(
                recordType: Document.ckRecordType, syncId: syncId, libraryId: libraryId, title: "Flight Notes",
                clientRecord: client, serverRecord: server, ancestorRecord: nil, detectedOn: Date()
            ))
        }
#endif

    }

    var body: some Scene {

        WindowGroup {
            RootView()
        }
        .modelContainer(self.sharedModelContainer)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Note") {
                    NotificationCenter.default.post(name: .kontinuumNewNote, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .toolbar) {
                Button("Command Palette…") {
                    NotificationCenter.default.post(name: .kontinuumOpenCommandPalette, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)
                Button("Quick Switcher") {
                    NotificationCenter.default.post(name: .kontinuumOpenQuickSwitcher, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    NotificationCenter.default.post(name: .kontinuumOpenSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            // Jumps matching the sectioned sidebar's new spine (Decision 2) — Capture vs.
            // Library vs. Explore, with Graph/Insights promoted to top-level Explore items.
            CommandMenu("View") {
                Button("Today") {
                    NotificationCenter.default.post(name: .kontinuumNavigate, object: AppDestination.today)
                }
                Button("Notebooks") {
                    NotificationCenter.default.post(name: .kontinuumNavigate, object: AppDestination.notebooks)
                }
                Button("Graph") {
                    NotificationCenter.default.post(name: .kontinuumNavigate, object: AppDestination.graph)
                }
                Button("Insights") {
                    NotificationCenter.default.post(name: .kontinuumNavigate, object: AppDestination.insights)
                }
            }
        }
#if os(macOS)
        .defaultSize(width: 1000, height: 700)
#endif

    }

}
