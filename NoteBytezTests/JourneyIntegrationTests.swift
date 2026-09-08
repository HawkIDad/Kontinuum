// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  JourneyIntegrationTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import CloudKit
import Foundation
@testable import NoteBytez

/// Phase 16 acceptance: Journeys 2-4 end-to-end, matching UIUX/02-Journeys.md. Journey 1
/// already has its own dedicated round-trip coverage in `ImportExportIntegrationTests`.
/// Journeys 2 and 4 are pure local-store flows and are fully exercised here. Journey 3 (a real
/// cross-device sync conflict) can only be driven up to the point CloudKit itself would
/// intervene — see that test's own note, matching the live-account/device gap already
/// documented for Phases 12-14.
struct JourneyIntegrationTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, Tag.self, DocumentTag.self, Notebook.self, DocumentNotebook.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - Journey 2: Daily capture -> journal -> link -> task

    @Test func journeyTwoDailyCaptureLinkTagTaskAndCrossDeviceToggle() throws {
        // A[Open Kontinuum on iPhone] -> B[Today's journal page already created and open]
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Mine", in: context)
        let libraryId = try #require(library.libraryId)
        let today = Date(timeIntervalSince1970: 1_700_000_000)

        let roadmap = DocumentDAL.create(title: "Q3 Roadmap", content: "Planning doc.", libraryId: libraryId, in: context)
        let roadmapId = try #require(roadmap.documentId)

        let journalEntry = JournalDAL.fetchOrCreate(for: today, libraryId: libraryId, in: context)
        // Idempotent: a second open of the app on the same day never creates a duplicate.
        let reopened = JournalDAL.fetchOrCreate(for: today, libraryId: libraryId, in: context)
        #expect(reopened.documentId == journalEntry.documentId)

        // C[Types a quick line] -> D[[[ autocompletes to an existing note] -> E[#tag] -> F[- [ ] task]
        let phoneViewModel = DocumentViewModel(document: journalEntry, modelContext: context)
        #expect(phoneViewModel.wikilinkSuggestions(matching: "Road") == ["Q3 Roadmap"])

        phoneViewModel.content += "\n- Discuss [[Q3 Roadmap]] #standup\n- [ ] Review PR from Dana"
        phoneViewModel.save()

        // G[Later, on Mac: opens the same synced journal entry] -> H[Backlink appears on the linked note]
        let journalId = try #require(journalEntry.documentId)
        let backlinks = BacklinkDAL.findBacklinks(to: "Q3 Roadmap", excluding: roadmapId, libraryId: libraryId, in: context)
        #expect(backlinks.count == 1)
        #expect(backlinks.first?.sourceDocument.documentId == journalId)

        #expect(phoneViewModel.tags.map { $0.name } == ["standup"])
        #expect(phoneViewModel.tasks.count == 1)
        #expect(phoneViewModel.tasks.first?.isDone == false)

        // I[Toggles the task from either the journal or the linked note - state is the same object]
        // No live CloudKit here, so "opens on Mac" is modeled as a second DocumentViewModel over
        // the same underlying Document/context — exactly what a synced-then-reloaded instance
        // would look like locally once CloudKit delivered the same records.
        let macViewModel = DocumentViewModel(document: journalEntry, modelContext: context)
        macViewModel.toggleTask(at: 0)

        phoneViewModel.reload()
        #expect(phoneViewModel.tasks.first?.isDone == true)
        #expect(phoneViewModel.content.contains("- [x] Review PR from Dana"))

        // J[Next day, uses Previous/Next day navigation to glance back at yesterday's journal]
        let tomorrow = JournalDAL.nextDate(after: today)
        #expect(JournalDAL.previousDate(before: tomorrow) == JournalDAL.startOfDay(today))
        #expect(JournalDAL.canNavigateToNextDay(from: today, today: tomorrow) == true)

        let yesterdayEntry = JournalDAL.fetch(for: JournalDAL.previousDate(before: today), libraryId: libraryId, in: context)
        #expect(yesterdayEntry == nil, "nothing was ever written for the day before today in this test")
        let todayAgain = JournalDAL.fetch(for: today, libraryId: libraryId, in: context)
        #expect(todayAgain?.documentId == journalId)
    }

    // MARK: - Journey 3: Sync status -> conflict encountered -> resolved

    /// A[Edits offline on iPhone] -> B[iPhone reconnects, sync runs] -> C[Conflict detected]
    /// is CloudKit's own job (`SyncEngine.makeConflict(from:)` and the private
    /// `handleDetectedConflict(_:)` dispatch it feeds), driven by a real `.serverRecordChanged`
    /// `CKError` — needs a live, signed-in iCloud account to trigger, the same gap already
    /// documented for Phases 12-14's own conflict tests. What's fully testable locally, and
    /// covered here, is every building block `handleDetectedConflict` composes: the
    /// status-indicator transitions (D-E), each of the three strategies' actual resolution
    /// decision, and the status returning to Synced once resolved (F-G) — using fresh
    /// `SyncStatusStore`/`ConflictStore` instances rather than `.shared`, matching Phase 13's
    /// own isolation pattern for these tests.
    @Test func journeyThreeConflictDetectedThroughEachStrategyToResolved() throws {
        let libraryId = UUID()
        let syncId = UUID()
        let zoneID = CKRecordZone.ID.library(libraryId)
        let recordID = CKRecord.ID.record(syncId: syncId, zoneID: zoneID)

        func makeConflict(clientContent: String, serverContent: String, clientUpdatedOn: Date, serverUpdatedOn: Date) -> Conflict {
            let client = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
            client["title"] = "Flight Notes"
            client["content"] = clientContent
            client["updatedOn"] = clientUpdatedOn

            let server = CKRecord(recordType: Document.ckRecordType, recordID: recordID)
            server["title"] = "Flight Notes"
            server["content"] = serverContent
            server["updatedOn"] = serverUpdatedOn

            return Conflict(
                recordType: Document.ckRecordType, syncId: syncId, libraryId: libraryId, title: "Flight Notes",
                clientRecord: client, serverRecord: server, ancestorRecord: nil, detectedOn: Date()
            )
        }

        // D[Sync status indicator changes from Synced to Conflict, badge on the affected note]
        let statusStore = SyncStatusStore()
        let conflictStore = ConflictStore()
        #expect(statusStore.status == .synced)

        let conflict = makeConflict(
            clientContent: "Wrote this on the plane.", serverContent: "Wrote this on the Mac.",
            clientUpdatedOn: Date(timeIntervalSince1970: 2000), serverUpdatedOn: Date(timeIntervalSince1970: 1000)
        )
        conflictStore.queue(conflict)
        statusStore.recordConflict(noteTitle: conflict.title)
        #expect(statusStore.status == .conflict)

        // E[Opens the sync log, sees which note conflicted and when each version was saved]
        #expect(conflictStore.conflict(syncId: syncId)?.title == "Flight Notes")
        let revisions = conflict.revisions
        #expect(Set(revisions.map(\.label)) == ["This Device", "Synced Elsewhere"])
        #expect(revisions.first { $0.kind == .client }?.timestamp == Date(timeIntervalSince1970: 2000))
        #expect(statusStore.logEntries.first?.message.contains("Flight Notes") == true)
        #expect(statusStore.logEntries.first?.isError == true)

        // F[Per their chosen conflict strategy, sees a merge banner / diff-merge / both kept]
        // Strategy: Keep All Versions — always queues for manual resolution, never auto-picks.
        let keepAllDefaults = UserDefaults(suiteName: "JourneyThree-\(UUID().uuidString)")!
        ConflictStrategyStore.setCurrentStrategy(.keepAllVersions, in: keepAllDefaults)
        #expect(ConflictStrategyStore.currentStrategy(in: keepAllDefaults) == .keepAllVersions)
        // (queued above; Keep All Versions never resolves on its own — S10 is reached instead)

        // Strategy: Last-Write-Wins + Banner — resolves immediately, newer edit wins.
        let lastWriteWinsChoice = ConflictResolver.lastWriteWinsChoice(for: conflict)
        #expect(lastWriteWinsChoice == .keepClient)
        let lastWriteWinsResolved = ConflictResolver.resolvedRecord(for: conflict, choice: lastWriteWinsChoice)
        #expect(lastWriteWinsResolved["content"] as? String == "Wrote this on the plane.")

        // Strategy: Markdown Diff-Merge — user reviews and accepts a merged hunk set.
        #expect(conflict.hasDiffableContent)
        let hunks = MarkdownDiffMerge.hunks(old: conflict.serverRecord["content"] as? String ?? "", new: conflict.clientRecord["content"] as? String ?? "")
        let acceptedIDs = Set(hunks.filter { $0.kind == .changed }.map(\.id))
        let merged = MarkdownDiffMerge.merge(hunks: hunks, acceptedHunkIDs: acceptedIDs)
        #expect(merged == "Wrote this on the plane.")
        let diffMergeResolved = ConflictResolver.resolvedRecord(for: conflict, choice: .merged(content: merged))
        #expect(diffMergeResolved["content"] as? String == merged)

        // G[Once resolved, status returns to Synced]
        conflictStore.remove(conflict)
        statusStore.decrementConflictCount()
        #expect(conflictStore.conflicts.isEmpty)
        #expect(statusStore.status == .synced)
    }

    // MARK: - Journey 4: Exploring the graph to resurface a forgotten note

    @Test func journeyFourSearchMissesGraphMissesTagBrowserFindsThenLinksBack() throws {
        let context = try makeContext()
        let library = LibraryDAL.create(name: "Archive", in: context)
        let libraryId = try #require(library.libraryId)

        let today = DocumentDAL.create(title: "2026-08-17", content: "Writing about the new onboarding flow.", libraryId: libraryId, in: context)
        // The half-remembered note: no keyword overlap with "today", not linked from it, only
        // findable by its tag — matching the journey's "not linked, so not in the graph" beat.
        let forgotten = DocumentDAL.create(
            title: "Elena's Sketch",
            content: "An early mockup for a guided setup wizard.\n\n#onboarding-idea",
            libraryId: libraryId, in: context
        )
        _ = TagDAL.syncTags(for: try #require(forgotten.documentId), content: forgotten.content ?? "", libraryId: libraryId, in: context)
        // A distractor the graph *can* find, to prove the graph step isn't just trivially empty.
        let linkedNeighbor = DocumentDAL.create(title: "Design System Notes", content: "See [[2026-08-17]] for context.", libraryId: libraryId, in: context)
        _ = linkedNeighbor

        // A[Tries Exact Search with a guessed keyword] -> B{Partial results, not quite it}
        let searchResults = SearchDAL.searchContent(query: "onboarding wizard", libraryId: libraryId, in: context)
        #expect(searchResults.contains { $0.document.documentId == forgotten.documentId } == false, "a keyword guess that doesn't match the note's actual words should miss")

        // C[Opens the current note's local graph view] -> D{Doesn't find it there either}
        let todayId = try #require(today.documentId)
        let graphEdges = GraphDAL.directLinks(for: today, libraryId: libraryId, in: context)
        #expect(graphEdges.contains { $0.documentId == forgotten.documentId } == false)
        #expect(graphEdges.contains { $0.documentId == linkedNeighbor.documentId } == true, "sanity check: the graph does surface an actually-linked neighbor")

        // E[Falls back to Quick Switcher / tag search, then Tag Browser to scan the full tag list]
        let tagSearchResults = SearchDAL.searchByTag(query: "onboarding-idea", libraryId: libraryId, in: context)
        #expect(tagSearchResults.contains { $0.document.documentId == forgotten.documentId })

        let allTags = TagDAL.fetchActive(libraryId: libraryId, in: context).map { $0.name }
        #expect(allTags.contains("onboarding-idea"))

        // F[Finds the note, opens it, sees its Backlinks pane, realizes it connects to others]
        // (Elena's Sketch has no backlinks yet — that's the point; it was truly forgotten.)
        let forgottenId = try #require(forgotten.documentId)
        let forgottenBacklinksBeforeLinking = BacklinkDAL.findBacklinks(to: "Elena's Sketch", excluding: forgottenId, libraryId: libraryId, in: context)
        #expect(forgottenBacklinksBeforeLinking.isEmpty)

        // G[Adds a new [[link]] from today's note to the rediscovered one, closing the loop]
        let todayViewModel = DocumentViewModel(document: today, modelContext: context)
        #expect(todayViewModel.wikilinkSuggestions(matching: "Elena") == ["Elena's Sketch"])
        todayViewModel.content += "\nRelated: [[Elena's Sketch]]"
        todayViewModel.save()

        let forgottenBacklinksAfterLinking = BacklinkDAL.findBacklinks(to: "Elena's Sketch", excluding: forgottenId, libraryId: libraryId, in: context)
        #expect(forgottenBacklinksAfterLinking.count == 1)
        #expect(forgottenBacklinksAfterLinking.first?.sourceDocument.documentId == todayId)

        // The note is no longer graph-orphaned from today's entry either, closing the loop both ways.
        let updatedGraphEdges = GraphDAL.directLinks(for: today, libraryId: libraryId, in: context)
        #expect(updatedGraphEdges.contains { $0.documentId == forgotten.documentId })
    }

}
