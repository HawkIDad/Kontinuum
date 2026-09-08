// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  GraphCanvas.swift
//  NoteBytez
//

import SwiftUI

/// S8's pan/zoom container: `centerDocument` renders as the filled center node, `linkedDocuments`
/// radiate around it in a simple circular layout — no force simulation/clustering, per Decisions
/// Log MVP scope. `scale`/`offset` are bindings so a host view can drive them from `[+][-][⤢]`
/// toolbar buttons as well as the built-in pinch/drag gestures.
struct GraphCanvas: View {

    let centerDocument: Document
    let linkedDocuments: [Document]
    var onSelect: (Document) -> Void = { _ in }

    @Binding var scale: CGFloat
    @Binding var offset: CGSize

    @GestureState private var pinchDelta: CGFloat = 1.0
    @GestureState private var dragDelta: CGSize = .zero

    static let minScale: CGFloat = 0.5
    static let maxScale: CGFloat = 2.5

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = max(min(geometry.size.width, geometry.size.height) / 2 - 60, 40)

            ZStack {
                Canvas { context, _ in
                    for index in linkedDocuments.indices {
                        var path = Path()
                        path.move(to: center)
                        path.addLine(to: nodePosition(index: index, center: center, radius: radius))
                        context.stroke(path, with: .color(.secondary.opacity(0.4)), lineWidth: 1)
                    }
                }

                Button {
                    onSelect(centerDocument)
                } label: {
                    GraphNode(title: centerDocument.title ?? "Untitled", isCenter: true)
                }
                .buttonStyle(.plain)
                .position(center)

                ForEach(Array(linkedDocuments.enumerated()), id: \.element.documentId) { index, document in
                    Button {
                        onSelect(document)
                    } label: {
                        GraphNode(title: document.title ?? "Untitled", isCenter: false)
                    }
                    .buttonStyle(.plain)
                    .position(nodePosition(index: index, center: center, radius: radius))
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
            .simultaneousGesture(
                DragGesture()
                    .updating($dragDelta) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        offset.width += value.translation.width
                        offset.height += value.translation.height
                    }
            )
        }
    }

    private func nodePosition(index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        guard !linkedDocuments.isEmpty else { return center }
        let angle = (2 * .pi / CGFloat(linkedDocuments.count)) * CGFloat(index) - (.pi / 2)
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }

}
