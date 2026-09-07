// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginBridgeTests.swift
//  KontinuumTests
//

import Testing
import Foundation
@testable import Kontinuum

/// Covers Phase 13's own required guarantees: permission-boundary enforcement (an ungranted
/// call throws rather than silently no-oping through omission), sandbox isolation (no
/// filesystem/network/other-document surface reachable from script code), and
/// malformed/malicious-script resilience (a syntax error or an infinite loop never takes down
/// the test process, i.e. never takes down the host app).
struct PluginBridgeTests {

    private func snapshot(documents: [PluginLibrarySnapshot.DocumentSummary] = [], tags: [String] = [], notebooks: [String] = []) -> PluginLibrarySnapshot {
        PluginLibrarySnapshot(documents: documents, tagNames: tags, notebookNames: notebooks)
    }

    // MARK: - Read library

    @Test func readLibraryGrantedListsDocumentsFromTheSnapshot() async {
        let bridge = PluginBridge(
            entryScript: """
            var docs = noteBytez.listDocuments();
            if (docs.length !== 1 || docs[0].title !== "Harbor Notes") { throw new Error("unexpected: " + JSON.stringify(docs)); }
            """,
            grantedPermissions: [.readLibrary],
            snapshot: snapshot(documents: [PluginLibrarySnapshot.DocumentSummary(id: "1", title: "Harbor Notes", content: "")])
        )

        #expect(await bridge.run() == .finished)
    }

    @Test func readLibraryUngrantedThrowsRatherThanReturningSilently() async {
        let bridge = PluginBridge(
            entryScript: "noteBytez.listDocuments();",
            grantedPermissions: [],
            snapshot: snapshot(documents: [PluginLibrarySnapshot.DocumentSummary(id: "1", title: "Secret", content: "")])
        )

        let result = await bridge.run()
        guard case .scriptError(let message) = result else {
            Issue.record("Expected .scriptError, got \(result)")
            return
        }
        #expect(message.contains("readLibrary"))
    }

    @Test func searchDocumentsMatchesTitleAndContentCaseInsensitively() async {
        let bridge = PluginBridge(
            entryScript: """
            var results = noteBytez.searchDocuments("harbor");
            if (results.length !== 1) { throw new Error("expected one match, got " + results.length); }
            """,
            grantedPermissions: [.readLibrary],
            snapshot: snapshot(documents: [
                PluginLibrarySnapshot.DocumentSummary(id: "1", title: "Harbor Notes", content: ""),
                PluginLibrarySnapshot.DocumentSummary(id: "2", title: "Unrelated", content: "no match here")
            ])
        )

        #expect(await bridge.run() == .finished)
    }

    // MARK: - Write current note

    @Test func writeCurrentNoteGrantedRecordsIntoTheCollector() async {
        let bridge = PluginBridge(entryScript: "noteBytez.appendToCurrentNote('hello');", grantedPermissions: [.writeCurrentNote], snapshot: snapshot())

        #expect(await bridge.run() == .finished)
        #expect(bridge.collector.appends == ["hello"])
    }

    @Test func writeCurrentNoteUngrantedThrowsAndRecordsNothing() async {
        let bridge = PluginBridge(entryScript: "noteBytez.appendToCurrentNote('hello');", grantedPermissions: [], snapshot: snapshot())

        let result = await bridge.run()
        guard case .scriptError(let message) = result else {
            Issue.record("Expected .scriptError, got \(result)")
            return
        }
        #expect(message.contains("writeCurrentNote"))
        #expect(bridge.collector.appends.isEmpty)
    }

    @Test func insertAtCursorGrantedRecordsIntoTheCollector() async {
        let bridge = PluginBridge(entryScript: "noteBytez.insertAtCursor('inserted');", grantedPermissions: [.writeCurrentNote], snapshot: snapshot())

        #expect(await bridge.run() == .finished)
        #expect(bridge.collector.inserts == ["inserted"])
    }

    // MARK: - Add command

    @Test func addCommandGrantedRegistersTheCommand() async {
        let bridge = PluginBridge(entryScript: "noteBytez.addCommand('Insert Word Count');", grantedPermissions: [.addCommand], snapshot: snapshot())

        #expect(await bridge.run() == .finished)
        #expect(bridge.collector.commands == ["Insert Word Count"])
    }

    @Test func addCommandUngrantedThrowsAndRegistersNothing() async {
        let bridge = PluginBridge(entryScript: "noteBytez.addCommand('Sneaky');", grantedPermissions: [], snapshot: snapshot())

        let result = await bridge.run()
        guard case .scriptError(let message) = result else {
            Issue.record("Expected .scriptError, got \(result)")
            return
        }
        #expect(message.contains("addCommand"))
        #expect(bridge.collector.commands.isEmpty)
    }

    // MARK: - A permission not granted at all still can't be reached by omission

    @Test func everyBridgeFunctionExistsRegardlessOfWhatWasGranted() async {
        let bridge = PluginBridge(
            entryScript: """
            var names = ["listDocuments", "searchDocuments", "listTags", "listNotebooks", "appendToCurrentNote", "insertAtCursor", "addCommand"];
            for (var i = 0; i < names.length; i++) {
                if (typeof noteBytez[names[i]] !== "function") { throw new Error("missing: " + names[i]); }
            }
            """,
            grantedPermissions: [],
            snapshot: snapshot()
        )

        #expect(await bridge.run() == .finished)
    }

    // MARK: - Invocation model

    @Test func registrationPassReceivesNullInvokedCommand() async {
        let bridge = PluginBridge(
            entryScript: "if (noteBytez.invokedCommand !== null) { throw new Error('expected null'); } noteBytez.addCommand('Do Thing');",
            grantedPermissions: [.addCommand],
            snapshot: snapshot()
        )

        #expect(await bridge.run(invokedCommand: nil) == .finished)
        #expect(bridge.collector.commands == ["Do Thing"])
    }

    @Test func invocationPassReceivesTheCommandNameAndOnlyActsOnAMatch() async {
        let script = """
        if (noteBytez.invokedCommand === "Do Thing") {
            noteBytez.appendToCurrentNote("did it");
        }
        """
        let bridge = PluginBridge(entryScript: script, grantedPermissions: [.writeCurrentNote], snapshot: snapshot())

        #expect(await bridge.run(invokedCommand: "Do Thing") == .finished)
        #expect(bridge.collector.appends == ["did it"])
    }

    @Test func invocationPassWithNoMatchingBranchDoesNothing() async {
        let script = """
        if (noteBytez.invokedCommand === "Something Else") {
            noteBytez.appendToCurrentNote("should not happen");
        }
        """
        let bridge = PluginBridge(entryScript: script, grantedPermissions: [.writeCurrentNote], snapshot: snapshot())

        #expect(await bridge.run(invokedCommand: "Do Thing") == .finished)
        #expect(bridge.collector.appends.isEmpty)
    }

    // MARK: - Sandbox isolation

    @Test func noFilesystemOrNetworkOrForeignGlobalsAreReachable() async {
        let script = """
        var forbidden = ["require", "XMLHttpRequest", "fetch", "FileManager", "NSFileManager", "process", "importScripts"];
        for (var i = 0; i < forbidden.length; i++) {
            if (typeof this[forbidden[i]] !== "undefined") { throw new Error("leaked: " + forbidden[i]); }
        }
        """
        let bridge = PluginBridge(entryScript: script, grantedPermissions: [.readLibrary, .writeCurrentNote, .addCommand], snapshot: snapshot())

        #expect(await bridge.run() == .finished)
    }

    @Test func readLibraryNeverExposesRawContentOnlyTitleAndSnippet() async {
        let script = """
        var docs = noteBytez.listDocuments();
        if (typeof docs[0].content !== "undefined") { throw new Error("content leaked"); }
        """
        let bridge = PluginBridge(
            entryScript: script,
            grantedPermissions: [.readLibrary],
            snapshot: snapshot(documents: [PluginLibrarySnapshot.DocumentSummary(id: "1", title: "T", content: "secret body text")])
        )

        #expect(await bridge.run() == .finished)
    }

    // MARK: - Malformed/malicious-script resilience

    @Test func syntaxErrorIsCaughtAsAScriptErrorNotACrash() async {
        let bridge = PluginBridge(entryScript: "this is not valid javascript {{{", grantedPermissions: [], snapshot: snapshot())

        guard case .scriptError = await bridge.run() else {
            Issue.record("Expected a caught .scriptError for invalid syntax")
            return
        }
    }

    @Test func thrownScriptExceptionIsCaughtNotPropagated() async {
        let bridge = PluginBridge(entryScript: "throw new Error('boom');", grantedPermissions: [], snapshot: snapshot())

        guard case .scriptError(let message) = await bridge.run() else {
            Issue.record("Expected .scriptError")
            return
        }
        #expect(message.contains("boom"))
    }

    @Test func emptyScriptReportsAnErrorRatherThanSilentlySucceeding() async {
        let bridge = PluginBridge(entryScript: "", grantedPermissions: [], snapshot: snapshot())

        guard case .scriptError = await bridge.run() else {
            Issue.record("Expected .scriptError for an empty script")
            return
        }
    }

    /// **Deliberately a bounded busy-loop (~4s), not a truly infinite one.** A genuinely
    /// unbounded `while (true) {}` reproduces `PluginRunResult.timedOut`'s documented
    /// limitation for real — the background thread it leaks never returns, since Apple's public
    /// `JavaScriptCore` API has no forced-interruption call — and a real `xcodebuild test` run
    /// hit exactly that: the leaked thread permanently pinned a core and starved this sandbox's
    /// small GCD worker pool, hanging the *entire* test process for 20+ minutes until killed.
    /// That's the correct, honest production behavior, but it's the wrong thing to reproduce
    /// unbounded inside an automated suite. A self-terminating busy-loop proves the same
    /// race — the bridge returns `.timedOut` well before the script's own loop ends — without
    /// leaving anything immortal behind afterward.
    @Test func infiniteLoopTimesOutInsteadOfHangingTheCaller() async {
        let bridge = PluginBridge(entryScript: "var start = Date.now(); while (Date.now() - start < 4000) {}", grantedPermissions: [], snapshot: snapshot())

        let start = Date()
        let result = await bridge.run()
        let elapsed = Date().timeIntervalSince(start)

        #expect(result == .timedOut)
        // Bounded by `PluginBridge.executionTimeLimit` (2s) — generous slack for CI scheduling
        // noise, but this proves the caller was never left waiting for the script's own ~4s.
        #expect(elapsed < PluginBridge.executionTimeLimit + 1.5)
    }

}
