// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphInsightsDALTests.swift
//  NoteBytezTests
//

import Testing
import SwiftData
import Foundation
@testable import NoteBytez

struct GraphInsightsDALTests {

    private func makeContext() throws -> ModelContext {
        let container = try ModelContainer(
            for: Library.self, Document.self, Block.self, TaskItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(container)
    }

    // MARK: - orphans

    @Test func orphansListsADocumentWithNoLinksInOrOut() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let orphan = DocumentDAL.create(title: "Orphan", content: "Nothing linked here.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Other", content: "No links either.", libraryId: libraryId, in: context)

        let orphans = GraphInsightsDAL.orphans(libraryId: libraryId, in: context)

        #expect(orphans.map { $0.documentId }.contains(orphan.documentId))
    }

    @Test func orphansExcludesADocumentWithOnlyAnIncomingLink() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target", content: "Nothing.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Source", content: "See [[Target]].", libraryId: libraryId, in: context)

        let orphans = GraphInsightsDAL.orphans(libraryId: libraryId, in: context)

        #expect(!orphans.map { $0.documentId }.contains(target.documentId))
    }

    @Test func orphansIncludesADocumentWithOnlyAnUnlinkedMentionSinceMentionsArentLinks() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Target", content: "Nothing.", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Source", content: "Mentions Target in passing, no brackets.", libraryId: libraryId, in: context)

        let orphans = GraphInsightsDAL.orphans(libraryId: libraryId, in: context)

        #expect(orphans.map { $0.documentId }.contains(target.documentId))
    }

    // MARK: - staleNotes

    @Test func staleListsAnOldDocumentWithAnOpenTask() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Old Project", content: "- [ ] Finish it", libraryId: libraryId, in: context)
        _ = TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)
        document.updatedOn = Date(timeIntervalSinceNow: -200 * 86400)

        let stale = GraphInsightsDAL.staleNotes(thresholdDays: 90, libraryId: libraryId, in: context)

        #expect(stale.map { $0.documentId }.contains(document.documentId))
    }

    @Test func staleListsAnOldDocumentWithABacklink() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let target = DocumentDAL.create(title: "Old Reference", content: "Nothing here.", libraryId: libraryId, in: context)
        target.updatedOn = Date(timeIntervalSinceNow: -200 * 86400)
        _ = DocumentDAL.create(title: "Source", content: "See [[Old Reference]].", libraryId: libraryId, in: context)

        let stale = GraphInsightsDAL.staleNotes(thresholdDays: 90, libraryId: libraryId, in: context)

        #expect(stale.map { $0.documentId }.contains(target.documentId))
    }

    @Test func staleExcludesAnOldAbandonedDocumentWithNoTasksAndNoBacklinksBecauseThatsAnOrphansJob() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Abandoned", content: "Nothing links here, no tasks.", libraryId: libraryId, in: context)
        document.updatedOn = Date(timeIntervalSinceNow: -200 * 86400)

        let stale = GraphInsightsDAL.staleNotes(thresholdDays: 90, libraryId: libraryId, in: context)

        #expect(!stale.map { $0.documentId }.contains(document.documentId))
    }

    @Test func staleExcludesARecentlyEditedDocument() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Fresh", content: "- [ ] Do this", libraryId: libraryId, in: context)
        _ = TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)

        let stale = GraphInsightsDAL.staleNotes(thresholdDays: 90, libraryId: libraryId, in: context)

        #expect(!stale.map { $0.documentId }.contains(document.documentId))
    }

    // MARK: - notesWithOpenTasks

    @Test func notesWithOpenTasksGroupsByDocumentWithCountAndNearestDueDate() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Project", content: "- [ ] First\n- [ ] Second", libraryId: libraryId, in: context)
        let documentId = try #require(document.documentId)
        let tasks = TaskDAL.syncTasks(for: documentId, libraryId: libraryId, in: context)
        tasks[0].dueDate = Date(timeIntervalSinceNow: 86400 * 5)
        tasks[1].dueDate = Date(timeIntervalSinceNow: 86400 * 1)

        let grouped = GraphInsightsDAL.notesWithOpenTasks(libraryId: libraryId, in: context)

        let entry = try #require(grouped.first { $0.document.documentId == documentId })
        #expect(entry.openCount == 2)
        #expect(entry.nearestDueDate == tasks[1].dueDate)
    }

    @Test func notesWithOpenTasksExcludesADocumentWhoseTasksAreAllDone() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let document = DocumentDAL.create(title: "Done Project", content: "- [x] Finished", libraryId: libraryId, in: context)
        _ = TaskDAL.syncTasks(for: try #require(document.documentId), libraryId: libraryId, in: context)

        let grouped = GraphInsightsDAL.notesWithOpenTasks(libraryId: libraryId, in: context)

        #expect(!grouped.contains { $0.document.documentId == document.documentId })
    }

    // MARK: - hubs

    @Test func hubsRanksByCombinedInAndOutDegree() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let hub = DocumentDAL.create(title: "Hub", content: "[[Leaf One]] [[Leaf Two]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf One", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Leaf Two", content: "", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Isolated", content: "", libraryId: libraryId, in: context)

        let hubs = GraphInsightsDAL.hubs(topN: 3, libraryId: libraryId, in: context)

        #expect(hubs.first?.document.documentId == hub.documentId)
        #expect(hubs.first?.degree == 2)
    }

    @Test func hubsBreaksTiesByTitle() throws {
        let context = try makeContext()
        let libraryId = UUID()
        _ = DocumentDAL.create(title: "Bravo", content: "[[Charlie]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Alpha", content: "[[Charlie]]", libraryId: libraryId, in: context)
        _ = DocumentDAL.create(title: "Charlie", content: "", libraryId: libraryId, in: context)

        let hubs = GraphInsightsDAL.hubs(topN: 3, libraryId: libraryId, in: context)

        #expect(hubs.first?.document.title == "Charlie")
        let tiedTitles = hubs.filter { $0.degree == 1 }.map { $0.document.title }
        #expect(tiedTitles == ["Alpha", "Bravo"])
    }

    // MARK: - clusters

    @Test func clustersGroupsDocumentsLinkedOnlyThroughAThirdIntoOneComponent() throws {
        let context = try makeContext()
        let libraryId = UUID()
        let a = DocumentDAL.create(title: "A", content: "[[B]]", libraryId: libraryId, in: context)
        let b = DocumentDAL.create(title: "B", content: "[[C]]", libraryId: libraryId, in: context)
        let c = DocumentDAL.create(title: "C", content: "", libraryId: libraryId, in: context)
        let orphan = DocumentDAL.create(title: "Orphan", content: "", libraryId: libraryId, in: context)

        let clusters = GraphInsightsDAL.clusters(libraryId: libraryId, in: context)
        let clusterIdSets = clusters.map { Set($0.compactMap { $0.documentId }) }

        #expect(clusterIdSets.contains(Set([a.documentId, b.documentId, c.documentId].compactMap { $0 })))
        #expect(clusterIdSets.contains(Set([orphan.documentId].compactMap { $0 })))
    }

    // MARK: - Performance guard (4.8)

    @Test func insightQueriesStayFastAtTwoThousandDocumentsAndSixThousandLinks() throws {
        let context = try makeContext()
        let libraryId = UUID()

        var titles: [String] = []
        for index in 0..<2000 {
            titles.append("Document \(index)")
        }
        var documents: [Document] = []
        for (index, title) in titles.enumerated() {
            // Three links per document (~6,000 total edges), each to a different, deterministic
            // neighbor so the graph is connected rather than 2,000 disjoint pairs.
            let targets = (1...3).map { titles[(index + $0) % titles.count] }
            let content = targets.map { "[[\($0)]]" }.joined(separator: " ")
            documents.append(DocumentDAL.create(title: title, content: content, libraryId: libraryId, in: context))
        }

        // `computeAll` is what `GraphInsightsViewModel.refresh()` actually calls — one shared
        // link-graph build for every category, not five independent re-scans of the library.
        let start = Date()
        _ = GraphInsightsDAL.computeAll(hubLimit: 20, libraryId: libraryId, in: context)
        let elapsed = Date().timeIntervalSince(start)

        #expect(elapsed < 0.25)
    }

}
