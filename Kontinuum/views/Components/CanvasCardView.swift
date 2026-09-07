// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasCardView.swift
//  Kontinuum
//

import SwiftUI
import SwiftData

/// Renders one `CanvasCard` by `cardType` — draggable (live-offset while dragging, committed via
/// `onMove` on release, so a card's position isn't written to the DAL on every frame) with a
/// bottom-right resize handle (same live-offset/commit-on-release shape via `onResize`). Tapping
/// a note/media/web card fires `onTap`; a `.group` card is a plain labeled boundary, not
/// individually tappable (per S16's own wireframe note — a group has no dedicated content to
/// open).
struct CanvasCardView: View {

    let card: CanvasCard
    var isConnecting: Bool = false
    var onTap: () -> Void = {}
    var onMove: (Double, Double) -> Void = { _, _ in }
    var onResize: (Double, Double) -> Void = { _, _ in }
    var onRemove: () -> Void = {}

    @Environment(\.modelContext) private var modelContext
    @GestureState private var dragOffset: CGSize = .zero
    @GestureState private var resizeOffset: CGSize = .zero

    private var width: CGFloat { CGFloat(card.width ?? CanvasDAL.defaultCardWidth) + resizeOffset.width }
    private var height: CGFloat { CGFloat(card.height ?? CanvasDAL.defaultCardHeight) + resizeOffset.height }

    private var title: String {
        switch card.canvasCardType {
        case .note:
            guard let documentId = card.documentId, let document = Document.fetch(syncId: documentId, in: modelContext) else { return "Missing Note" }
            return document.title?.isEmpty == false ? document.title! : "Untitled"
        case .media:
            guard let attachmentId = card.attachmentId, let attachment = Attachment.fetch(syncId: attachmentId, in: modelContext) else { return "Missing Attachment" }
            return attachment.fileName ?? "Attachment"
        case .web:
            return card.url ?? ""
        case .group, .none:
            return card.label ?? "Group"
        }
    }

    private var systemImage: String {
        switch card.canvasCardType {
        case .note: return "doc.text"
        case .media: return "photo"
        case .web: return "globe"
        case .group, .none: return "rectangle.dashed"
        }
    }

    var body: some View {
        Group {
            if card.canvasCardType == .group {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .foregroundStyle(.secondary)
                    .overlay(alignment: .topLeading) {
                        Text(title)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(6)
                    }
            } else {
                Button(action: onTap) {
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: systemImage)
                            .foregroundStyle(Color.accentColor)
                        Text(title)
                            .font(.callout)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.primary)
                    }
                    .padding(10)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
                .buttonStyle(.plain)
                .background(Color.noteBytezSecondarySurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(isConnecting ? Color.accentColor : Color.clear, lineWidth: 2)
                }
            }
        }
        .frame(width: width, height: height)
        .offset(dragOffset)
        .contextMenu {
            Button("Remove", systemImage: "trash", role: .destructive, action: onRemove)
        }
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: "arrow.down.right.and.arrow.up.left")
                .font(.caption2)
                .padding(4)
                .background(Color.noteBytezSecondarySurface)
                .clipShape(Circle())
                .offset(resizeOffset)
                .gesture(
                    DragGesture()
                        .updating($resizeOffset) { value, state, _ in state = value.translation }
                        .onEnded { value in
                            onResize((card.width ?? CanvasDAL.defaultCardWidth) + value.translation.width, (card.height ?? CanvasDAL.defaultCardHeight) + value.translation.height)
                        }
                )
                .accessibilityLabel("Resize card")
                .accessibilityHint("Drag to resize")
        }
        // `simultaneousGesture`, not `gesture`: a plain `.gesture()` here would take priority
        // over the inner `Button`'s own tap recognizer and silently swallow every tap — found by
        // testing on-device, where `onTap` never fired at all despite drag/resize working fine.
        .simultaneousGesture(
            DragGesture()
                .updating($dragOffset) { value, state, _ in state = value.translation }
                .onEnded { value in
                    onMove((card.positionX ?? 0) + value.translation.width, (card.positionY ?? 0) + value.translation.height)
                }
        )
    }

}
