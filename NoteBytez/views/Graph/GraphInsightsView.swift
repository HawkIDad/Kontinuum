// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphInsightsView.swift
//  NoteBytez
//

import SwiftUI

/// S25 — Graph Insights (Decision 1). A read-only "answerable views" screen, not a
/// force-directed graph: Orphans, Stale, Notes with Open Tasks, Hubs, and Clusters, each
/// computed on demand by `GraphInsightsDAL`. An empty category always renders a calm empty
/// state (`styleGuide.md`), never a blank section.
struct GraphInsightsView: View {

    @Bindable var viewModel: GraphInsightsViewModel

    @Environment(\.modelContext) private var modelContext
    @State private var navigationTarget: Document?
    @State private var sentCanvasBoard: CanvasBoard?

    private static let thresholdChoices = [30, 60, 90, 180]

    var body: some View {
        List {
            Section {
                InsightSectionHeader(title: "Orphans", count: viewModel.orphans.count, description: "No incoming or outgoing links.")
                if viewModel.orphans.isEmpty {
                    emptyState("No orphans — every note is connected.")
                } else {
                    ForEach(viewModel.orphans) { document in
                        row(for: document, detail: "Unconnected", systemImage: "questionmark.circle")
                    }
                }
            }

            Section {
                InsightSectionHeader(title: "Stale", count: viewModel.staleNotes.count, description: "Untouched for a while, but still has open tasks or backlinks.")
                Picker("Threshold", selection: $viewModel.staleThresholdDays) {
                    ForEach(Self.thresholdChoices, id: \.self) { days in
                        Text("\(days) days").tag(days)
                    }
                }
                .pickerStyle(.segmented)
                if viewModel.staleNotes.isEmpty {
                    emptyState("Nothing stale — every note that still matters has been touched recently.")
                } else {
                    ForEach(viewModel.staleNotes) { document in
                        row(for: document, detail: document.updatedOn?.formatted(date: .abbreviated, time: .omitted) ?? "", systemImage: "clock")
                    }
                }
            }

            Section {
                InsightSectionHeader(title: "Notes with Open Tasks", count: viewModel.notesWithOpenTasks.count, description: "Grouped by note, with the count and nearest due date.")
                if viewModel.notesWithOpenTasks.isEmpty {
                    emptyState("No open tasks anywhere.")
                } else {
                    ForEach(viewModel.notesWithOpenTasks, id: \.document.documentId) { entry in
                        row(
                            for: entry.document,
                            detail: entry.nearestDueDate.map { "\(entry.openCount) open · due \($0.formatted(date: .abbreviated, time: .omitted))" } ?? "\(entry.openCount) open",
                            systemImage: "checklist"
                        )
                    }
                }
            }

            Section {
                InsightSectionHeader(title: "Hubs", count: viewModel.hubs.count, description: "Ranked by combined incoming and outgoing links.")
                if viewModel.hubs.isEmpty {
                    emptyState("No hubs yet — link some notes together.")
                } else {
                    ForEach(viewModel.hubs, id: \.document.documentId) { entry in
                        row(for: entry.document, detail: "\(entry.degree) links", systemImage: "point.3.connected.trianglepath.dotted")
                    }
                }
            }

            Section {
                InsightSectionHeader(title: "Clusters", count: viewModel.clusterGroups.count, description: "Connected groups of notes, headed by their most-linked member.")
                if viewModel.clusterGroups.isEmpty {
                    emptyState("No clusters yet.")
                } else {
                    ForEach(viewModel.clusterGroups) { cluster in
                        DisclosureGroup("Cluster: \(cluster.headline.title ?? "Untitled") — \(cluster.members.count) notes") {
                            ForEach(cluster.members) { document in
                                row(for: document, detail: "", systemImage: "doc.text")
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button {
                                sentCanvasBoard = CanvasDAL.seedBoard(fromCluster: cluster.members, libraryId: viewModel.libraryId, in: modelContext)
                            } label: {
                                Label("Open as Canvas", systemImage: "square.grid.2x2")
                            }
                            .tint(.accentColor)
                        }
                        .contextMenu {
                            Button {
                                sentCanvasBoard = CanvasDAL.seedBoard(fromCluster: cluster.members, libraryId: viewModel.libraryId, in: modelContext)
                            } label: {
                                Label("Open as Canvas", systemImage: "square.grid.2x2")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Insights")
        .noteBytezInlineNavigationTitle()
        .onAppear { viewModel.refresh() }
        .navigationDestination(item: $navigationTarget) { document in
            DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
        }
        .navigationDestination(item: $sentCanvasBoard) { board in
            CanvasBoardView(viewModel: CanvasViewModel(libraryId: viewModel.libraryId, modelContext: modelContext), board: board)
        }
    }

    private func row(for document: Document, detail: String, systemImage: String) -> some View {
        Button {
            navigationTarget = document
        } label: {
            GraphInsightRow(title: document.title ?? "", detail: detail, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.callout)
            .foregroundStyle(.secondary)
    }

}
