// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  ForceGraphCanvas.swift
//  Kontinuum
//

import SwiftUI

/// S8's Force mode (Decision 4/A5) — a `ForceSimulation` stepped by `TimelineView(.animation)`
/// until it settles, then static. Sibling to the MVP `GraphCanvas` (radial, unchanged); this one
/// supports N hops (`GraphViewModel.neighborhood`), edges between any two members (not just
/// focus↔node), and drag-to-pin. Same pinch/zoom/pan bindings and control shape as `GraphCanvas`
/// so `GraphView`'s existing `[+][-][⤢]` toolbar works unmodified for either mode.
struct ForceGraphCanvas: View {

    let focusDocument: Document
    let neighborhood: [(document: Document, hopDistance: Int)]
    let edges: [ForceDirectedLayout.Edge]
    var onSelect: (Document) -> Void = { _ in }
    var isHighlighted: (Document) -> Bool = { _ in false }

    @Binding var scale: CGFloat
    @Binding var offset: CGSize

    @State private var simulation: ForceSimulation
    @State private var dragOffsetsByNode: [UUID: CGSize] = [:]

    @GestureState private var pinchDelta: CGFloat = 1.0
    @GestureState private var dragDelta: CGSize = .zero

    static let minScale: CGFloat = 0.5
    static let maxScale: CGFloat = 2.5

    private var allMembers: [(document: Document, hopDistance: Int)] {
        [(document: focusDocument, hopDistance: 0)] + neighborhood
    }

    init(
        focusDocument: Document,
        neighborhood: [(document: Document, hopDistance: Int)],
        edges: [ForceDirectedLayout.Edge],
        onSelect: @escaping (Document) -> Void = { _ in },
        isHighlighted: @escaping (Document) -> Bool = { _ in false },
        scale: Binding<CGFloat>,
        offset: Binding<CGSize>
    ) {
        self.focusDocument = focusDocument
        self.neighborhood = neighborhood
        self.edges = edges
        self.onSelect = onSelect
        self.isHighlighted = isHighlighted
        self._scale = scale
        self._offset = offset

        var nodes: [ForceDirectedLayout.Node] = []
        if let focusId = focusDocument.documentId { nodes.append(ForceDirectedLayout.Node(id: focusId)) }
        nodes.append(contentsOf: neighborhood.compactMap { $0.document.documentId.map(ForceDirectedLayout.Node.init) })
        self._simulation = State(initialValue: ForceSimulation(nodes: nodes, edges: edges))
    }

    var body: some View {
        TimelineView(.animation) { timeline in
            ZStack {
                Canvas { context, _ in
                    for edge in edges {
                        guard let from = simulation.positions[edge.from], let to = simulation.positions[edge.to] else { continue }
                        var path = Path()
                        path.move(to: from)
                        path.addLine(to: to)
                        context.stroke(path, with: .color(.secondary.opacity(0.4)), lineWidth: 1)
                    }
                }

                ForEach(allMembers, id: \.document.documentId) { member in
                    if let id = member.document.documentId, let position = simulation.positions[id] {
                        nodeView(for: member.document, hopDistance: member.hopDistance)
                            .position(x: position.x + (dragOffsetsByNode[id]?.width ?? 0), y: position.y + (dragOffsetsByNode[id]?.height ?? 0))
                            .gesture(dragGesture(id: id, basePosition: position, document: member.document))
                    }
                }
            }
            .onChange(of: timeline.date) { _, _ in
                if !simulation.isSettled { simulation.step() }
            }
        }
        .scaleEffect(scale * pinchDelta)
        .offset(x: offset.width + dragDelta.width, y: offset.height + dragDelta.height)
        .gesture(
            MagnificationGesture()
                .updating($pinchDelta) { value, state, _ in state = value }
                .onEnded { value in
                    scale = min(max(scale * value, Self.minScale), Self.maxScale)
                }
        )
    }

    private func nodeView(for document: Document, hopDistance: Int) -> some View {
        Button {
            onSelect(document)
        } label: {
            GraphNode(title: document.title ?? "Untitled", isCenter: hopDistance == 0)
                .opacity(hopDistance == 0 ? 1 : max(1 - Double(hopDistance) * 0.2, 0.4))
                .overlay {
                    if isHighlighted(document) {
                        Circle().stroke(Color.accentColor, lineWidth: 2).padding(-3)
                    }
                }
        }
        .buttonStyle(.plain)
        // A8/E5: the node stays a plain VoiceOver list item whose label carries what the visual
        // styling encodes (center vs. hop distance, tag-scope highlight) so neither is colour-only.
        .accessibilityLabel(accessibilityLabel(for: document, hopDistance: hopDistance))
    }

    private func accessibilityLabel(for document: Document, hopDistance: Int) -> String {
        let title = document.title ?? "Untitled"
        let position = hopDistance == 0 ? "focus note" : "\(hopDistance) hop\(hopDistance == 1 ? "" : "s") away"
        let highlight = isHighlighted(document) ? ", matches tag scope" : ""
        return "\(title), \(position)\(highlight)"
    }

    /// A drag beyond a small threshold pins the node at the drop point ("the simulation
    /// continues around it"); anything shorter is treated as a tap and falls through to the
    /// node's own `Button` action (`onSelect`) instead — `minimumDistance` on this gesture keeps
    /// a plain tap from ever reaching `onChanged`/`onEnded` here at all.
    private func dragGesture(id: UUID, basePosition: CGPoint, document: Document) -> some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                dragOffsetsByNode[id] = value.translation
            }
            .onEnded { value in
                let dropPoint = CGPoint(x: basePosition.x + value.translation.width, y: basePosition.y + value.translation.height)
                dragOffsetsByNode[id] = nil
                simulation.pin(id, at: dropPoint)
            }
    }

}
