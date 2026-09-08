// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasConnectorView.swift
//  NoteBytez
//

import SwiftUI

/// Draws every `CanvasConnector` on a board as a line (with a plain arrowhead — see Phase 9's
/// stated `fromEnd`/`toEnd` scope cut) plus an optional label at its midpoint, between the two
/// cards' *committed* positions — a line snaps into place when a drag ends rather than tracking
/// the dragged card's live offset frame-by-frame, since that offset is local `CanvasCardView`
/// gesture state, not hoisted up here. Named `CanvasConnectorView` (not `CanvasConnector`) since
/// that name is already the model's — see Phase 9's own naming note.
struct CanvasConnectorView: View {

    let connectors: [CanvasConnector]
    let cards: [CanvasCard]

    private func center(of cardId: UUID?) -> CGPoint? {
        guard let cardId, let card = cards.first(where: { $0.canvasCardId == cardId }) else { return nil }
        let width = card.width ?? CanvasDAL.defaultCardWidth
        let height = card.height ?? CanvasDAL.defaultCardHeight
        return CGPoint(x: (card.positionX ?? 0) + width / 2, y: (card.positionY ?? 0) + height / 2)
    }

    var body: some View {
        Canvas { context, _ in
            for connector in connectors {
                guard let from = center(of: connector.fromCardId), let to = center(of: connector.toCardId) else { continue }

                var path = Path()
                path.move(to: from)
                path.addLine(to: to)

                let strokeColor = connector.color.flatMap { Color(hex: $0) } ?? Color.secondary.opacity(0.6)
                context.stroke(path, with: .color(strokeColor), lineWidth: 1.5)
                drawArrowhead(in: &context, from: from, to: to, color: strokeColor)

                if let label = connector.label, !label.isEmpty {
                    let midpoint = CGPoint(x: (from.x + to.x) / 2, y: (from.y + to.y) / 2)
                    let text = Text(label).font(.caption2).foregroundStyle(strokeColor)
                    context.draw(text, at: midpoint, anchor: .center)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawArrowhead(in context: inout GraphicsContext, from: CGPoint, to: CGPoint, color: Color) {
        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLength: CGFloat = 10
        let arrowAngle = CGFloat.pi / 7

        let point1 = CGPoint(x: to.x - arrowLength * cos(angle - arrowAngle), y: to.y - arrowLength * sin(angle - arrowAngle))
        let point2 = CGPoint(x: to.x - arrowLength * cos(angle + arrowAngle), y: to.y - arrowLength * sin(angle + arrowAngle))

        var arrowPath = Path()
        arrowPath.move(to: to)
        arrowPath.addLine(to: point1)
        arrowPath.move(to: to)
        arrowPath.addLine(to: point2)
        context.stroke(arrowPath, with: .color(color), lineWidth: 1.5)
    }

}

private extension Color {

    /// JSON Canvas's hex-string node/edge color (`"#RRGGBB"`) — the preset `"1"`-`"6"` form
    /// isn't translated to a specific hue (out of scope for a first cut); it falls through to
    /// the caller's default secondary color instead of a wrong guess.
    init?(hex: String) {
        var sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        guard sanitized.hasPrefix("#") else { return nil }
        sanitized.removeFirst()
        guard sanitized.count == 6, let value = UInt32(sanitized, radix: 16) else { return nil }
        let red = Double((value >> 16) & 0xFF) / 255
        let green = Double((value >> 8) & 0xFF) / 255
        let blue = Double(value & 0xFF) / 255
        self = Color(red: red, green: green, blue: blue)
    }

}
