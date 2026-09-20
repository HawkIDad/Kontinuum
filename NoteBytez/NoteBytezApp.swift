// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  NoteBytezApp.swift
//  NoteBytez
//
//  Created by David Collison on 8/13/26.
//

import SwiftUI
import SwiftData
import CloudKit

@main
struct NoteBytezApp: App {

#if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    var sharedModelContainer: ModelContainer

    init() {

#if DEBUG
        // `-ResetLanguagePreference`: `LocalePreferenceStore` persists to `UserDefaults.standard`,
        // which (unlike the in-memory SwiftData store) survives across launches on the same
        // simulator — so a UI test that specifically exercises the first-launch prompt (Phase
        // 5.8(a)) needs a way to force a clean slate rather than assume it's the first time
        // this simulator has ever run the app. DEBUG-only, launch-argument-gated, mirroring
        // `-SkipLanguagePrompt` below.
        if ProcessInfo.processInfo.arguments.contains("-ResetLanguagePreference") {
            LocalePreferenceStore.reset()
        }

        // `-SkipLanguagePrompt` (Phase 5.7, R7): every `NoteBytezUITestCase`-based launch (and
        // this file's own `-SeedTestConflict(s)` fixtures) expects to land directly on S1 or the
        // main shell — the first-launch language prompt would otherwise block all of them, since
        // it now precedes everything else in `RootView`. Mirrors `-SeedTestConflict`'s DEBUG-only,
        // launch-argument-gated seam.
        if ProcessInfo.processInfo.arguments.contains("-SkipLanguagePrompt") {
            LocalePreferenceStore.markPromptedForLanguage()
        }
#endif

        // MultiLanguage Phase 5.6: re-assert whatever language preference is already stored
        // into `AppleLanguages` before the `ModelContainer`/`WindowGroup` below are built — see
        // `LocalePreferenceStore.reapplyPreferredLanguage` for why this is a defensive no-op
        // rather than new behavior.
        LocalePreferenceStore.reapplyPreferredLanguage()

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
        // Entitlement gate (NoteBytez20260907v1-Security.md Phase 5): if the cached entitlement
        // already says "blocked", start sync suspended so a lapsed/never-subscribed launch
        // never pushes or destructively applies before `EntitlementGateViewModel` re-checks.
        if EntitlementGateViewModel.launchShouldSuspendSync() {
            SyncEngine.shared.suspend()
        }
#else
        if isLiveSyncTestingEnabled {
            SyncEngine.shared.start(modelContainer: self.sharedModelContainer)
        }

        // `-SeedTestConflict` queues a synthetic Document conflict into `ConflictStore.shared`
        // at launch, so the UI test suite can drive S9/S10 (and Journey 3/8's downstream
        // conflict-resolution UI) without a live CloudKit `.serverRecordChanged` error — the
        // same test-only, DEBUG-gated seam `-EnableLiveSync` establishes above. Mirrors the
        // fixture in `NoteBytezTests/JourneyIntegrationTests.swift`'s
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

        // `-SeedTestConflicts` (plural) — the manual, two-simulator variant: stands up a
        // ready-to-use "Sync Test" library with two *distinct* queued conflicts and one pending
        // Last-Write-Wins auto-resolution, so S9/S10 and the `ConflictBanner` revert flow can be
        // exercised on a device with no live CloudKit. Unlike `-SeedTestConflict` above it also
        // writes real SwiftData rows (library + note), so the XCUITest suite deliberately does
        // not opt into it.
        if ProcessInfo.processInfo.arguments.contains("-SeedTestConflicts") {
            Self.seedTestConflicts(into: self.sharedModelContainer)
        }

        // `SeedScreenshotLibrary` (folder) or `SeedScreenshotNotes` (inline JSON) builds the website screenshot library from a folder
        // of fixture .md files (WebSite20260919v1-WebSite.md Phase W4). DEBUG-only, like the
        // seams above.
        if ScreenshotSeeder.seedFromSettings(in: ModelContext(self.sharedModelContainer)) {
            if let destination = ScreenshotSeeder.destination(named: ScreenshotSeeder.setting("ScreenshotDestination")) {
                ScreenshotSeeder.scheduleNavigation(to: destination)
            }
            if let appearance = ScreenshotSeeder.Appearance(name: ScreenshotSeeder.setting("ScreenshotAppearance")) {
                ScreenshotSeeder.apply(appearance)
            }
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
                    NotificationCenter.default.post(name: .noteBytezNewNote, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .toolbar) {
                Button("Command Palette…") {
                    NotificationCenter.default.post(name: .noteBytezOpenCommandPalette, object: nil)
                }
                .keyboardShortcut("p", modifiers: .command)
                Button("Quick Switcher") {
                    NotificationCenter.default.post(name: .noteBytezOpenQuickSwitcher, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    NotificationCenter.default.post(name: .noteBytezOpenSettings, object: nil)
                }
                .keyboardShortcut(",", modifiers: .command)
            }
            // Jumps matching the sectioned sidebar's new spine (Decision 2) — Capture vs.
            // Library vs. Explore, with Graph/Insights promoted to top-level Explore items.
            CommandMenu("View") {
                Button("Today") {
                    NotificationCenter.default.post(name: .noteBytezNavigate, object: AppDestination.today)
                }
                Button("Notebooks") {
                    NotificationCenter.default.post(name: .noteBytezNavigate, object: AppDestination.notebooks)
                }
                Button("Graph") {
                    NotificationCenter.default.post(name: .noteBytezNavigate, object: AppDestination.graph)
                }
                Button("Insights") {
                    NotificationCenter.default.post(name: .noteBytezNavigate, object: AppDestination.insights)
                }
            }
        }
#if os(macOS)
        .defaultSize(width: 1000, height: 700)
#endif

    }

}

#if DEBUG
// MARK: - Manual multi-issue sync fixture (`-SeedTestConflicts`)

extension NoteBytezApp {

    /// Seeds a selectable library plus a realistic mix of unresolved sync issues — two queued
    /// conflicts (one diffable `Document`, one non-diffable `Library` root) and one pending
    /// Last-Write-Wins auto-resolution on a real note. Drives the orange status glyph, S9's
    /// "Needs Your Attention" list, S10, and S4's `ConflictBanner` without a live `CKSyncEngine`.
    static func seedTestConflicts(into container: ModelContainer) {
        let context = ModelContext(container)

        let library = LibraryDAL.create(name: "Sync Test", in: context)
        guard let libraryId = library.libraryId else { return }

        let meetingNote = DocumentDAL.create(
            title: "Meeting Notes",
            content: "Kickoff moved to Thursday.\nOwners: TBD.",
            libraryId: libraryId,
            in: context
        )
        try? context.save()

        LibraryDAL.setSelectedLibraryId(libraryId)
        TemplateOnboardingStore.markCompleted()
        // Pin the strategy so the fixture is self-contained — S10's manual keep-all UI is the
        // one the "two queued conflicts" scenario is about (and `UserDefaults` otherwise
        // carries over whatever a previous launch selected).
        ConflictStrategyStore.setCurrentStrategy(.keepAllVersions)

        let zoneID = CKRecordZone.ID.library(libraryId)

        queueDocumentContentConflict(libraryId: libraryId, zoneID: zoneID)
        queueLibraryRecordConflict(libraryId: libraryId, zoneID: zoneID)

        if let documentId = meetingNote.documentId {
            recordPendingAutoResolution(documentId: documentId, libraryId: libraryId, zoneID: zoneID)
        }
    }

    /// Issue 1 — competing note bodies. `content` on both sides makes this diffable, so S10
    /// offers Keep This / Keep Both / Markdown Diff-Merge.
    private static func queueDocumentContentConflict(libraryId: UUID, zoneID: CKRecordZone.ID) {
        let syncId = UUID()
        let recordID = CKRecord.ID.record(syncId: syncId, zoneID: zoneID)

        let client = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
        client["title"] = "Draft Proposal"
        client["content"] = "Budget: $12k.\nTimeline: 6 weeks.\nOwner: Dana."
        client["updatedOn"] = Date(timeIntervalSinceNow: -120)

        let server = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
        server["title"] = "Draft Proposal"
        server["content"] = "Budget: $15k.\nTimeline: 4 weeks.\nOwner: Dana."
        server["updatedOn"] = Date(timeIntervalSinceNow: -300)

        ConflictStore.shared.queue(Conflict(
            recordType: Document.ckRecordType, syncId: syncId, libraryId: libraryId,
            title: "Draft Proposal", clientRecord: client, serverRecord: server,
            ancestorRecord: nil, detectedOn: Date()
        ))
        SyncStatusStore.shared.recordConflict(noteTitle: "Draft Proposal")
    }

    /// Issue 2 — a `Library` root-record conflict (e.g. renamed on two devices). No `content`,
    /// so S10 falls back to last-write-wins with no Keep Both — the real Journey 3 path.
    private static func queueLibraryRecordConflict(libraryId: UUID, zoneID: CKRecordZone.ID) {
        let syncId = UUID()
        let recordID = CKRecord.ID.record(syncId: syncId, zoneID: zoneID)

        let client = CKRecord(recordType: Library.ckRecordType, recordID: recordID)
        client["name"] = "Sync Test — renamed on this device"
        client["updatedOn"] = Date(timeIntervalSinceNow: -60)

        let server = CKRecord(recordType: Library.ckRecordType, recordID: recordID)
        server["name"] = "Sync Test — renamed elsewhere"
        server["updatedOn"] = Date(timeIntervalSinceNow: -200)

        ConflictStore.shared.queue(Conflict(
            recordType: Library.ckRecordType, syncId: syncId, libraryId: libraryId,
            title: "Sync Test", clientRecord: client, serverRecord: server,
            ancestorRecord: nil, detectedOn: Date()
        ))
        SyncStatusStore.shared.recordConflict(noteTitle: "Sync Test")
    }

    /// Issue 3 — a still-open auto-resolution on the seeded "Meeting Notes" note. Opening that
    /// note shows `ConflictBanner` ("Kept this device's edit…") with a working Revert.
    private static func recordPendingAutoResolution(documentId: UUID, libraryId: UUID, zoneID: CKRecordZone.ID) {
        let recordID = CKRecord.ID.record(syncId: documentId, zoneID: zoneID)

        let client = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
        client["title"] = "Meeting Notes"
        client["content"] = "Kickoff moved to Thursday.\nOwners: TBD."
        client["updatedOn"] = Date(timeIntervalSinceNow: -30)

        let server = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
        server["title"] = "Meeting Notes"
        server["content"] = "Kickoff still Monday."
        server["updatedOn"] = Date(timeIntervalSinceNow: -90)

        let conflict = Conflict(
            recordType: Document.ckRecordType, syncId: documentId, libraryId: libraryId,
            title: "Meeting Notes", clientRecord: client, serverRecord: server,
            ancestorRecord: nil, detectedOn: Date()
        )
        ConflictStore.shared.recordAutoResolution(ConflictAutoResolution(
            conflict: conflict, kept: .keepClient, keptLabel: "this device's edit"
        ))
        SyncStatusStore.shared.recordResolvedConflict(noteTitle: "Meeting Notes")
    }

}
#endif
