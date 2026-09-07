// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData

/// S8 — Local Graph View. Two modes (Decision 4): **Radial** (MVP default) — current note as
/// the filled center node, its direct links as surrounding outlined nodes, no simulation.
/// **Force** (opt-in, Workstream A) — a Fruchterman-Reingold simulation over a filterable,
/// multi-hop neighborhood.
struct GraphView: View {

    @Bindable var viewModel: GraphViewModel

    @Environment(\.modelContext) private var modelContext
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var selectedDocument: Document?
    @State private var sentCanvasBoard: CanvasBoard?
    @State private var isPresentingFilterBar = false
    @State private var isPresentingSaveAsView = false
    @State private var saveAsViewName = ""

    private var titleText: String {
        let title = viewModel.document.title ?? ""
        return title.isEmpty ? "Graph" : title
    }

    /// Matches the A7 performance guard's ceiling — beyond this, force mode shows a calm
    /// "narrow the filter" state instead of janking (`styleGuide.md`'s empty-state convention).
    private static let maxForceModeNodeCount = 500

    var body: some View {
        Group {
            switch viewModel.mode {
            case .radial:
                GraphCanvas(
                    centerDocument: viewModel.document,
                    linkedDocuments: viewModel.linkedDocuments,
                    onSelect: { document in select(document) },
                    scale: $scale,
                    offset: $offset
                )
            case .force:
                if viewModel.neighborhood.count > Self.maxForceModeNodeCount {
                    ContentUnavailableView(
                        "Graph Too Large",
                        systemImage: "circle.grid.cross",
                        description: Text("Narrow the filter — reduce the depth or node types — to render this many notes as a force graph.")
                    )
                } else {
                    ForceGraphCanvas(
                        focusDocument: viewModel.document,
                        neighborhood: viewModel.neighborhood,
                        edges: viewModel.forceModeEdges,
                        onSelect: { document in select(document) },
                        isHighlighted: { viewModel.isHighlighted($0) },
                        scale: $scale,
                        offset: $offset
                    )
                }
            }
        }
        .overlay(alignment: .top) {
            if viewModel.mode == .force, isPresentingFilterBar {
                GraphFilterBar(filter: $viewModel.filter, onSaveAsView: { isPresentingSaveAsView = true })
                    .padding()
                    .background(.regularMaterial)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 12) {
                Button {
                    scale = min(scale + 0.25, GraphCanvas.maxScale)
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                }
                .accessibilityLabel("Zoom In")

                Button {
                    scale = max(scale - 0.25, GraphCanvas.minScale)
                } label: {
                    Image(systemName: "minus.magnifyingglass")
                }
                .accessibilityLabel("Zoom Out")

                Button {
                    scale = 1.0
                    offset = .zero
                } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .accessibilityLabel("Fit to Screen")
            }
            .buttonStyle(.bordered)
            .padding()
        }
        .navigationTitle(titleText)
        .noteBytezInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Mode", selection: $viewModel.mode) {
                    ForEach(GraphMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            if viewModel.mode == .force {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        isPresentingFilterBar.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filters")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    sendToCanvas()
                } label: {
                    Label("Send to Canvas", systemImage: "square.grid.2x2")
                }
                .accessibilityLabel("Send to Canvas")
            }
        }
        .navigationDestination(item: $selectedDocument) { document in
            DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
        }
        .navigationDestination(item: $sentCanvasBoard) { board in
            CanvasBoardView(viewModel: CanvasViewModel(libraryId: viewModel.document.libraryId ?? UUID(), modelContext: modelContext), board: board)
        }
        .alert("Save Graph Filter", isPresented: $isPresentingSaveAsView) {
            TextField("Name", text: $saveAsViewName)
            Button("Cancel", role: .cancel) { saveAsViewName = "" }
            Button("Save") {
                guard !saveAsViewName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                viewModel.saveFilterAsView(name: saveAsViewName)
                saveAsViewName = ""
            }
        }
    }

    private func select(_ document: Document) {
        guard document.documentId != viewModel.document.documentId else { return }
        selectedDocument = document
    }

    /// Seeds a new `CanvasBoard` from this note's neighborhood (Decision 4) and navigates into
    /// it — the graph becomes a *source* for spatial work rather than a dead-end visualization.
    /// One-time seed, no live binding back: re-tapping this button creates another new board.
    private func sendToCanvas() {
        guard let libraryId = viewModel.document.libraryId else { return }
        sentCanvasBoard = CanvasDAL.seedBoard(fromNeighborhoodOf: viewModel.document, libraryId: libraryId, in: modelContext)
    }

}

/// A6's collapsible filter bar — depth stepper, node-type toggles, tag-scope field, "Save as
/// View." Node-type toggles are independent (a node can match more than one class), so this is
/// a row of `Toggle`s rather than `FilterChipRow` (which is single-select only).
private struct GraphFilterBar: View {

    @Binding var filter: GraphFilter
    var onSaveAsView: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Stepper("Depth: \(filter.depth) hop\(filter.depth == 1 ? "" : "s")", value: $filter.depth, in: 1...3)

            HStack(spacing: 8) {
                nodeTypeToggle("Notes", isOn: $filter.showPlainNotes)
                nodeTypeToggle("Open Tasks", isOn: $filter.showNotesWithOpenTasks)
                nodeTypeToggle("Orphans", isOn: $filter.showOrphans)
            }

            HStack {
                Image(systemName: "tag")
                    .foregroundStyle(.secondary)
                TextField("Highlight tag…", text: Binding(
                    get: { filter.tagScope ?? "" },
                    set: { filter.tagScope = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.plain)
            }

            Button("Save as View", action: onSaveAsView)
                .buttonStyle(.bordered)
        }
    }

    private func nodeTypeToggle(_ title: String, isOn: Binding<Bool>) -> some View {
        Button {
            isOn.wrappedValue.toggle()
        } label: {
            Text(title)
        }
        .buttonStyle(.bordered)
        .tint(isOn.wrappedValue ? .accentColor : .secondary)
        .controlSize(.small)
    }

}
