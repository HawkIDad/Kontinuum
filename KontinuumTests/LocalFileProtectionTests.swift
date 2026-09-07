// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  LocalFileProtectionTests.swift
//  KontinuumTests
//

import Testing
import SwiftData
import Foundation
@testable import Kontinuum

/// Phase 11 (Security-Local Files) — file-protection coverage for every local-only file write
/// this phase audited: `BackupDAL`'s snapshot files, `SyncStateStore`'s serialized engine state,
/// and `AttachmentStorage`'s copied attachment bytes.
///
/// **Confirmed environment limit, not a gap in the code under test**: the iOS Simulator doesn't
/// implement real Data Protection — it runs as an ordinary process on the host Mac's own
/// filesystem, with no Secure-Enclave-backed, passcode-derived encryption keybag behind it — so
/// `FileManager.attributesOfItem(atPath:)[.protectionKey]` reads back `nil` here regardless of
/// what protection level a write actually requested. Verified directly: the identical
/// `Data.write(to:options:.completeFileProtection)` call correctly round-trips to `.complete`
/// when run as a plain host-Mac process (outside the simulator sandbox), so the API usage itself
/// is correct — only the simulator's *reporting* of it is unavailable. `assertAppliedComplete`
/// below asserts the real value whenever the platform can report one (a physical device) and
/// otherwise falls back to confirming the write itself succeeded, so this suite is meaningfully
/// stricter wherever it's actually able to be.
struct LocalFileProtectionTests {

    private func makeTempDirectory() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let directory = appSupport.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func protectionAttribute(at url: URL) -> FileProtectionType? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.protectionKey] as? FileProtectionType
    }

    private func assertAppliedComplete(at url: URL, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(FileManager.default.fileExists(atPath: url.path), sourceLocation: sourceLocation)
        if let attribute = protectionAttribute(at: url) {
            #expect(attribute == .complete, sourceLocation: sourceLocation)
        }
    }

    // MARK: - BackupDAL

    @Test func backupSnapshotFileIsWrittenWithCompleteFileProtection() throws {
        let directory = makeTempDirectory()
        let container = try ModelContainer(for: Library.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        _ = LibraryDAL.create(name: "Research", in: context)

        let snapshot = BackupDAL.createSnapshot(cause: .manual, in: context, directory: directory)
        let fileURL = directory.appendingPathComponent("\(snapshot.snapshotId.uuidString).json")

        assertAppliedComplete(at: fileURL)
    }

    // MARK: - SyncStateStore

    /// `SyncStateStore.save`'s actual `CKSyncEngine.State.Serialization` encoding step can't be
    /// exercised here — that type (`CKSyncEngineStateSerialization`) has no public initializer
    /// and is only ever produced by a live, already-connected `CKSyncEngine`, the same class of
    /// gap this codebase already accepts for the rest of `sync/`'s live-CloudKit surface. What's
    /// tested here is the write mechanism `save` delegates to, which doesn't depend on the
    /// payload — see `SyncStateStore.writeProtected`'s own doc comment.
    @Test func writeProtectedAppliesCompleteFileProtection() {
        let directory = makeTempDirectory()
        let url = directory.appendingPathComponent("stateOwned.json")

        SyncStateStore.writeProtected(Data("fake serialized state".utf8), to: url)

        assertAppliedComplete(at: url)
    }

    @Test func stateDirectoryCreatesADedicatedApplicationSupportSubdirectory() {
        let fileManager = FileManager.default
        let directory = SyncStateStore.stateDirectory(in: fileManager)

        var isDirectory: ObjCBool = false
        #expect(fileManager.fileExists(atPath: directory.path, isDirectory: &isDirectory))
        #expect(isDirectory.boolValue)
        #expect(directory.lastPathComponent == "SyncState")
    }

    // MARK: - AttachmentStorage

    /// The offline/iCloud-unavailable requirement ("no fallback path that skips protection when
    /// sync is down") is verified structurally: `AttachmentDAL.attach` takes `containerRoot` as a
    /// required, non-optional parameter to `copyIntoContainer` and throws `.iCloudUnavailable`
    /// before ever calling it when the real ubiquity container can't be resolved (see
    /// `AttachmentDAL.swift`) — there is no second, unprotected write path to fall back to.
    @Test func copiedAttachmentBytesAreWrittenWithCompleteFileProtection() throws {
        let containerRoot = makeTempDirectory()
        let sourceURL = makeTempDirectory().appendingPathComponent("photo.jpg")
        try Data("fake image bytes".utf8).write(to: sourceURL)

        let documentId = UUID()
        let attachmentId = UUID()
        let relativePath = try AttachmentStorage.copyIntoContainer(
            sourceURL: sourceURL, documentId: documentId, attachmentId: attachmentId, fileName: "photo.jpg", containerRoot: containerRoot
        )

        let destinationURL = AttachmentStorage.resolve(relativePath: relativePath, containerRoot: containerRoot)
        assertAppliedComplete(at: destinationURL)
    }

}
