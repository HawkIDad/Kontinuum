// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphInsightsViewModel.swift
//  NoteBytez
//

import Foundation
import SwiftData
import Observation

/// Backs `GraphInsightsView` (S25). `@Observable`, scan-on-demand — `refresh()` re-runs
/// `GraphInsightsDAL.computeAll` fresh each time, same "no cache to invalidate" rationale as
/// every other computed-on-demand DAL in this app.
@Observable
final class GraphInsightsViewModel {

    /// One connected component, presented headed by its highest-degree member (Decision 1's
    /// "Clusters" presentation, Phase 4.5) — a display shape, not a `GraphInsightsDAL` type.
    struct ClusterGroup: Identifiable {
        let id: UUID
        let headline: Document
        let members: [Document]
    }

    let libraryId: UUID
    private let modelContext: ModelContext

    private(set) var orphans: [Document] = []
    private(set) var staleNotes: [Document] = []
    private(set) var notesWithOpenTasks: [GraphInsightsDAL.OpenTasksEntry] = []
    private(set) var hubs: [GraphInsightsDAL.HubEntry] = []
    private(set) var clusterGroups: [ClusterGroup] = []

    var staleThresholdDays: Int {
        didSet {
            guard staleThresholdDays != oldValue else { return }
            GraphInsightsThresholdStore.setCurrentThresholdDays(staleThresholdDays)
            refresh()
        }
    }

    init(libraryId: UUID, modelContext: ModelContext) {
        self.libraryId = libraryId
        self.modelContext = modelContext
        self.staleThresholdDays = GraphInsightsThresholdStore.currentThresholdDays()
        refresh()
    }

    func refresh() {
        let snapshot = GraphInsightsDAL.computeAll(thresholdDays: staleThresholdDays, libraryId: libraryId, in: modelContext)
        orphans = snapshot.orphans
        staleNotes = snapshot.staleNotes
        notesWithOpenTasks = snapshot.notesWithOpenTasks
        hubs = snapshot.hubs

        // Every document's degree (not just the top-N "Hubs" section's) to pick each cluster's
        // headline member.
        let degreeById = Dictionary(uniqueKeysWithValues: GraphInsightsDAL.hubs(topN: .max, libraryId: libraryId, in: modelContext).compactMap { entry -> (UUID, Int)? in
            guard let id = entry.document.documentId else { return nil }
            return (id, entry.degree)
        })
        clusterGroups = snapshot.clusters.compactMap { members in
            guard let headline = members.max(by: { (degreeById[$0.documentId ?? UUID()] ?? 0) < (degreeById[$1.documentId ?? UUID()] ?? 0) }),
                  let headlineId = headline.documentId
            else { return nil }
            return ClusterGroup(id: headlineId, headline: headline, members: members)
        }
    }

}
