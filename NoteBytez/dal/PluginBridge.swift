// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  PluginBridge.swift
//  Kontinuum
//

import Foundation
import JavaScriptCore
import SwiftData

/// A read-only, pre-fetched view of the library a plugin script is allowed to query — captured
/// on the caller's thread *before* the script runs, so the sandboxed JS never touches
/// `ModelContext` (which is not safe to use off the thread/actor it was created on) directly.
/// Plain `Sendable` data, safe to hand to the background thread `PluginBridge.run` evaluates
/// script on.
struct PluginLibrarySnapshot: Sendable {

    struct DocumentSummary: Sendable {
        let id: String
        let title: String
        let content: String
    }

    let documents: [DocumentSummary]
    let tagNames: [String]
    let notebookNames: [String]

    static let empty = PluginLibrarySnapshot(documents: [], tagNames: [], notebookNames: [])

    static func capture(libraryId: UUID, in context: ModelContext) -> PluginLibrarySnapshot {
        let documents = DocumentDAL.fetchActive(libraryId: libraryId, in: context).map {
            DocumentSummary(id: $0.documentId?.uuidString ?? "", title: $0.title ?? "", content: $0.content ?? "")
        }
        let tagNames = TagDAL.fetchActive(libraryId: libraryId, in: context).compactMap { $0.name }
        let notebookNames = NotebookDAL.fetchActive(libraryId: libraryId, in: context).compactMap { $0.name }
        return PluginLibrarySnapshot(documents: documents, tagNames: tagNames, notebookNames: notebookNames)
    }

}

/// Collects everything a script asked the write-current-note/add-command APIs to do, so the
/// bridge layer never mutates app state *from the background thread the script runs on* — the
/// caller applies whatever landed here only after `PluginBridge.run` returns, back on its own
/// thread/actor. `@unchecked Sendable`: mutated from the script's background thread and read
/// from the caller's thread, safe because every access is serialized through `lock`.
nonisolated final class PluginWriteCollector: @unchecked Sendable {

    private let lock = NSLock()
    private var appendedText: [String] = []
    private var insertedText: [String] = []
    private var registeredCommandNames: [String] = []

    func recordAppend(_ text: String) {
        lock.lock(); defer { lock.unlock() }
        appendedText.append(text)
    }

    /// No cursor position — see `PluginBridge.installBridge`'s `insertAtCursor` note; the host
    /// (`DocumentViewModel.applyPluginWrites`) currently treats this the same as an append.
    func recordInsert(_ text: String) {
        lock.lock(); defer { lock.unlock() }
        insertedText.append(text)
    }

    func recordCommand(_ name: String) {
        lock.lock(); defer { lock.unlock() }
        registeredCommandNames.append(name)
    }

    var appends: [String] {
        lock.lock(); defer { lock.unlock() }
        return appendedText
    }

    var inserts: [String] {
        lock.lock(); defer { lock.unlock() }
        return insertedText
    }

    var commands: [String] {
        lock.lock(); defer { lock.unlock() }
        return registeredCommandNames
    }

}

nonisolated enum PluginRunResult: Equatable, Sendable {
    case finished
    /// The script did not finish within `PluginBridge.executionTimeLimit`. Apple's public
    /// `JavaScriptCore` API offers no way to forcibly interrupt a running script (the private
    /// WebKit-era `JSContextGroupSetExecutionTimeLimit` C function isn't part of the shipping
    /// framework), so the calling thread simply stops waiting and returns — the runaway
    /// background thread is abandoned rather than killed. This keeps the host app itself
    /// responsive and crash-free (this task's actual requirement), at the honestly-documented
    /// cost of a leaked thread for a truly malicious/broken script, the same class of accepted,
    /// non-general mitigation `AdvancedSearchParser`'s regex-ReDoS reject heuristic already
    /// established for this codebase (see Phase 5). Any writes/commands the abandoned thread
    /// later records into its `PluginWriteCollector` are never applied, since the caller only
    /// reads the collector when this case is `.finished`.
    case timedOut
    case scriptError(String)
}

/// Sandboxed execution for one `Plugin`, per NoteBytez-R1-Implementation.md Phase 13 and
/// Decisions Log #3: a script gets exactly three bridge APIs (read library / write current note
/// / add command), each gated by the plugin's own `grantedPermissions`, and nothing else —
/// no filesystem, no network, no other-document access, no persisted/background execution.
///
/// **Execution model**: a script runs synchronously, once, whenever it needs to act — either to
/// register its commands (`invokedCommand == nil`, expected to call `noteBytez.addCommand(name)`
/// for each command it offers) or to actually run one (`invokedCommand` set to the command's
/// name, which the script itself is expected to branch on). Nothing about a plugin persists
/// between runs — no live `JSContext`/`JSValue` callback is ever kept around — so every
/// invocation re-checks permissions from scratch and there's no stale-closure state to reason
/// about. This is a deliberately simpler model than capturing a JS callback function per
/// command; it fits a "preview"-scope SDK and this app's own "no background execution" rule.
nonisolated final class PluginBridge {

    static let executionTimeLimit: TimeInterval = 2.0

    // Plain Sendable values, not a live `Plugin` — that `@Model` instance is bound to the
    // `ModelContext`'s actor (this target's default `MainActor` isolation) and this bridge is
    // deliberately `nonisolated` so `run()` can dispatch script evaluation onto a background
    // thread. The caller (`PluginViewModel`, on `MainActor`) reads the model once up front and
    // hands over copies.
    private let entryScript: String?
    private let grantedPermissions: Set<PluginPermission>
    private let snapshot: PluginLibrarySnapshot
    let collector = PluginWriteCollector()

    init(entryScript: String?, grantedPermissions: Set<PluginPermission>, snapshot: PluginLibrarySnapshot) {
        self.entryScript = entryScript
        self.grantedPermissions = grantedPermissions
        self.snapshot = snapshot
    }

    /// Runs the plugin's entry script to completion, to a timeout, or to a caught script error.
    /// `async`, and deliberately never blocks a thread synchronously to wait for the result.
    ///
    /// This took two attempts to get right, both caught by this file's own test suite rather
    /// than shipped broken: a `DispatchSemaphore.wait(timeout:)` version starved Swift's
    /// cooperative thread pool whenever `run()` was called from an async context (every test hit
    /// the full timeout, not just the ones meant to). A `withTaskGroup` version replaced the
    /// blocking wait but reintroduced the same deadlock structurally: a task group will not let
    /// its own scope return until *every* child task actually finishes, even after
    /// `cancelAll()` — and the script-evaluation child can never respond to cancellation (it's a
    /// synchronous C call inside a `withCheckedContinuation`, not a Task that checks
    /// `Task.isCancelled`). A truly hung script therefore hung `run()` itself, which hung the
    /// entire `xcodebuild test` process for 20+ minutes until it had to be killed.
    ///
    /// The fix: `Task.detached` is *unstructured* — nothing waits for it. Racing two detached
    /// tasks against a single `withCheckedContinuation`, guarded by `PluginRunResultLatch` so
    /// only the first one to finish resumes it, lets the timeout side genuinely win and return
    /// while the hung script keeps running, abandoned, exactly as `PluginRunResult.timedOut`
    /// documents.
    @discardableResult
    func run(invokedCommand: String? = nil) async -> PluginRunResult {
        guard let script = entryScript?.trimmingCharacters(in: .whitespacesAndNewlines), !script.isEmpty else {
            return .scriptError("Plugin has no entry script")
        }

        let grantedPermissions = self.grantedPermissions
        let snapshot = self.snapshot
        let collector = self.collector
        let timeLimit = Self.executionTimeLimit

        let scriptTask = Task.detached(priority: .userInitiated) { () -> PluginRunResult in
            await withCheckedContinuation { (continuation: CheckedContinuation<PluginRunResult, Never>) in
                DispatchQueue.global(qos: .userInitiated).async {
                    let context = JSContext()
                    var caughtMessage: String?
                    context?.exceptionHandler = { _, exception in
                        caughtMessage = exception?.toString() ?? "Unknown plugin script error"
                    }
                    Self.installBridge(into: context, grantedPermissions: grantedPermissions, snapshot: snapshot, collector: collector, invokedCommand: invokedCommand)
                    context?.evaluateScript(script)
                    continuation.resume(returning: caughtMessage.map { .scriptError($0) } ?? .finished)
                }
            }
        }

        let latch = PluginRunResultLatch()

        return await withCheckedContinuation { (continuation: CheckedContinuation<PluginRunResult, Never>) in
            Task {
                let result = await scriptTask.value
                if latch.claim() { continuation.resume(returning: result) }
            }
            Task {
                try? await Task.sleep(nanoseconds: UInt64(timeLimit * 1_000_000_000))
                if latch.claim() { continuation.resume(returning: .timedOut) }
            }
        }
    }

    /// Installs `noteBytez.*` on `context`. Static and parameterized rather than an instance
    /// method, so nothing captured by the closures below reaches back into `self` — the closures
    /// run on the background thread `run()` dispatched to, and `self`/`Plugin`/`ModelContext`
    /// are not safe to touch from there.
    private static func installBridge(into context: JSContext?, grantedPermissions: Set<PluginPermission>, snapshot: PluginLibrarySnapshot, collector: PluginWriteCollector, invokedCommand: String?) {
        guard let context else { return }

        let noteBytez = JSValue(newObjectIn: context)

        let denyPermission: (JSContext, PluginPermission) -> Void = { context, permission in
            context.exception = JSValue(newErrorFromMessage: "Permission denied: \(permission.rawValue)", in: context)
        }

        let listDocuments: @convention(block) () -> [[String: String]] = {
            guard grantedPermissions.contains(.readLibrary) else {
                denyPermission(context, .readLibrary)
                return []
            }
            return snapshot.documents.map { ["id": $0.id, "title": $0.title] }
        }

        let searchDocuments: @convention(block) (String) -> [[String: String]] = { query in
            guard grantedPermissions.contains(.readLibrary) else {
                denyPermission(context, .readLibrary)
                return []
            }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return [] }
            return snapshot.documents
                .filter { $0.title.localizedCaseInsensitiveContains(trimmed) || $0.content.localizedCaseInsensitiveContains(trimmed) }
                .map { ["id": $0.id, "title": $0.title] }
        }

        let listTags: @convention(block) () -> [String] = {
            guard grantedPermissions.contains(.readLibrary) else {
                denyPermission(context, .readLibrary)
                return []
            }
            return snapshot.tagNames
        }

        let listNotebooks: @convention(block) () -> [String] = {
            guard grantedPermissions.contains(.readLibrary) else {
                denyPermission(context, .readLibrary)
                return []
            }
            return snapshot.notebookNames
        }

        let appendToCurrentNote: @convention(block) (String) -> Bool = { text in
            guard grantedPermissions.contains(.writeCurrentNote) else {
                denyPermission(context, .writeCurrentNote)
                return false
            }
            collector.recordAppend(text)
            return true
        }

        let insertAtCursor: @convention(block) (String) -> Bool = { text in
            guard grantedPermissions.contains(.writeCurrentNote) else {
                denyPermission(context, .writeCurrentNote)
                return false
            }
            // The script has no way to know the real cursor offset (it never sees editor
            // state) — see `PluginWriteCollector.recordInsert`'s note on how the host
            // currently applies this.
            collector.recordInsert(text)
            return true
        }

        let addCommand: @convention(block) (String) -> Bool = { name in
            guard grantedPermissions.contains(.addCommand) else {
                denyPermission(context, .addCommand)
                return false
            }
            collector.recordCommand(name)
            return true
        }

        noteBytez?.setObject(listDocuments, forKeyedSubscript: "listDocuments" as NSString)
        noteBytez?.setObject(searchDocuments, forKeyedSubscript: "searchDocuments" as NSString)
        noteBytez?.setObject(listTags, forKeyedSubscript: "listTags" as NSString)
        noteBytez?.setObject(listNotebooks, forKeyedSubscript: "listNotebooks" as NSString)
        noteBytez?.setObject(appendToCurrentNote, forKeyedSubscript: "appendToCurrentNote" as NSString)
        noteBytez?.setObject(insertAtCursor, forKeyedSubscript: "insertAtCursor" as NSString)
        noteBytez?.setObject(addCommand, forKeyedSubscript: "addCommand" as NSString)
        if let invokedCommand {
            noteBytez?.setObject(invokedCommand, forKeyedSubscript: "invokedCommand" as NSString)
        } else {
            noteBytez?.setObject(JSValue(nullIn: context), forKeyedSubscript: "invokedCommand" as NSString)
        }

        context.setObject(noteBytez, forKeyedSubscript: "noteBytez" as NSString)
    }

}

/// Guards `run()`'s race so only the first of "script finished" / "timeout elapsed" resumes the
/// continuation — resuming a `CheckedContinuation` twice is a runtime trap, and both racers are
/// unstructured `Task`s with no ordering guarantee between them.
nonisolated private final class PluginRunResultLatch: @unchecked Sendable {

    private let lock = NSLock()
    private var claimed = false

    func claim() -> Bool {
        lock.lock(); defer { lock.unlock() }
        if claimed { return false }
        claimed = true
        return true
    }

}
