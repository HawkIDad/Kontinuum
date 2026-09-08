// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasBoardView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// S16 — Canvas. Infinite pan/zoom board: `CanvasCardView`s positioned absolutely, connector
/// lines drawn underneath by `CanvasConnectorView`. Extends `GraphCanvas`'s already-proven
/// pinch/pan mechanism (`MagnificationGesture` + `DragGesture`, scale/offset driven by both the
/// gesture and the `[+][-][⤢]` toolbar, same S8 pattern `GraphView` already uses) rather than a
/// new gesture system.
struct CanvasBoardView: View {

    var viewModel: CanvasViewModel
    let board: CanvasBoard

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var pinchDelta: CGFloat = 1.0
    @GestureState private var panDelta: CGSize = .zero

    @State private var isConnecting = false
    @State private var connectingFromCard: CanvasCard?

    @State private var isPresentingAddNote = false
    @State private var isPresentingAddMedia = false
    @State private var isPresentingAddWebAlert = false
    @State private var isPresentingAddGroupAlert = false
    @State private var newWebURL = ""
    @State private var newGroupLabel = ""

    @State private var navigationTarget: Document?
    @State private var previewedAttachment: Attachment?
    @State private var isPresentingExport = false
    @State private var isPresentingBindPicker = false
    @State private var pendingConnector: (from: CanvasCard, to: CanvasCard)?

    static let minScale: CGFloat = 0.5
    static let maxScale: CGFloat = 2.5

    /// Cascades each newly-added card a little further down-right so repeated additions never
    /// stack exactly on top of one another.
    private var nextCardOrigin: (x: Double, y: Double) {
        let index = Double(viewModel.cards.count)
        return (200 + index.truncatingRemainder(dividingBy: 6) * 40, 200 + index.truncatingRemainder(dividingBy: 6) * 40)
    }

    /// Split into `canvasScreen` + this chain of sheets/alerts, and further into `canvasContent`/
    /// `zoomControls`/`toolbarContent` below: the compiler timed out type-checking the whole
    /// screen (pan/zoom canvas, toolbar, zoom overlay, four sheets/alerts, a navigation
    /// destination, and a file exporter) as one expression — a known Swift complexity cliff, not
    /// a logic issue. Splitting into named sub-expressions fixes it.
    var body: some View {
        canvasScreen
            .sheet(isPresented: $isPresentingAddNote) {
                AddNoteCardSheet(viewModel: viewModel, isPresented: $isPresentingAddNote, origin: nextCardOrigin)
            }
            .sheet(isPresented: $isPresentingAddMedia) {
                AddMediaCardSheet(viewModel: viewModel, isPresented: $isPresentingAddMedia, origin: nextCardOrigin)
            }
            .alert("Add Web Link", isPresented: $isPresentingAddWebAlert) {
                TextField("https://example.com", text: $newWebURL)
                    .autocorrectionDisabled()
#if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.URL)
#endif
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    let trimmed = newWebURL.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    viewModel.addWebCard(url: trimmed, x: nextCardOrigin.x, y: nextCardOrigin.y)
                }
            }
            .alert("Add Group", isPresented: $isPresentingAddGroupAlert) {
                TextField("Label", text: $newGroupLabel)
                Button("Cancel", role: .cancel) {}
                Button("Add") {
                    let trimmed = newGroupLabel.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    viewModel.addGroupCard(label: trimmed, x: nextCardOrigin.x, y: nextCardOrigin.y)
                }
            }
            .navigationDestination(item: $navigationTarget) { document in
                DocumentView(viewModel: DocumentViewModel(document: document, modelContext: modelContext))
            }
            .sheet(item: $previewedAttachment) { attachment in
                AttachmentPreview(attachment: attachment)
            }
            .sheet(isPresented: $isPresentingBindPicker) {
                BindBoardSheet(viewModel: viewModel, board: board, isPresented: $isPresentingBindPicker)
            }
            .alert("Create Link?", isPresented: Binding(get: { pendingConnector != nil }, set: { if !$0 { pendingConnector = nil } })) {
                Button("Cancel", role: .cancel) { pendingConnector = nil }
                Button("Create Link") { confirmPendingConnector() }
            } message: {
                Text(pendingConnectorMessage)
            }
            .fileExporter(
                isPresented: $isPresentingExport,
                document: CanvasFileDocument(text: viewModel.exportJSON() ?? "{\"nodes\":[],\"edges\":[]}"),
                contentType: UTType(filenameExtension: "canvas") ?? .json,
                defaultFilename: board.name ?? "Board"
            ) { _ in }
    }

    private var canvasScreen: some View {
        canvasContent
            .overlay(alignment: .bottomTrailing) { zoomControls }
            .overlay(alignment: .topLeading) { boundChrome }
            .navigationTitle(board.name ?? "Canvas")
            .noteBytezInlineNavigationTitle()
            .toolbar { toolbarContent }
            .onAppear {
                viewModel.load(board)
                NotificationCenter.default.post(name: .noteBytezActiveCanvasBoardChanged, object: board)
            }
            .onDisappear {
                NotificationCenter.default.post(name: .noteBytezActiveCanvasBoardChanged, object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: .noteBytezTriggerBindCanvas)) { _ in
                isPresentingBindPicker = true
            }
    }

    private var canvasContent: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                panBackground
                CanvasConnectorView(connectors: viewModel.connectors, cards: viewModel.cards)
                cardsLayer
            }
            .frame(width: max(geometry.size.width, 2000), height: max(geometry.size.height, 2000))
            .scaleEffect(scale * pinchDelta)
            .offset(x: offset.width + panDelta.width, y: offset.height + panDelta.height)
            .gesture(
                MagnificationGesture()
                    .updating($pinchDelta) { value, state, _ in state = value }
                    .onEnded { value in
                        scale = min(max(scale * value, Self.minScale), Self.maxScale)
                    }
            )
        }
    }

    private var zoomControls: some View {
        HStack(spacing: 12) {
            Button { scale = min(scale + 0.25, Self.maxScale) } label: { Image(systemName: "plus.magnifyingglass") }
                .accessibilityLabel("Zoom In")
            Button { scale = max(scale - 0.25, Self.minScale) } label: { Image(systemName: "minus.magnifyingglass") }
                .accessibilityLabel("Zoom Out")
            Button { scale = 1.0; offset = .zero } label: { Image(systemName: "arrow.up.left.and.arrow.down.right") }
                .accessibilityLabel("Fit to Screen")
        }
        .buttonStyle(.bordered)
        .padding()
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) { addCardMenu }
        ToolbarItem(placement: .primaryAction) { connectToggleButton }
        ToolbarItem(placement: .secondaryAction) { bindButton }
        ToolbarItem(placement: .secondaryAction) { exportButton }
    }

    @ViewBuilder
    private var bindButton: some View {
        if board.boundDocumentId != nil {
            Button {
                viewModel.unbind(board)
            } label: {
                Label("Unbind", systemImage: "link.badge.minus")
            }
        } else {
            Button {
                isPresentingBindPicker = true
            } label: {
                Label("Bind to Note…", systemImage: "link.badge.plus")
            }
        }
    }

    @ViewBuilder
    private var boundChrome: some View {
        if let title = viewModel.boundDocumentTitle(for: board) {
            Text("↔ \(title)")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.thinMaterial, in: Capsule())
                .padding(8)
                .accessibilityLabel("Bound to \(title)")
        }
    }

    private var addCardMenu: some View {
        Menu {
            Button("Add Note…", systemImage: "doc.text") { isPresentingAddNote = true }
            Button("Add Media…", systemImage: "photo") { isPresentingAddMedia = true }
            Button("Add Web Link…", systemImage: "globe") { newWebURL = ""; isPresentingAddWebAlert = true }
            Button("Add Group…", systemImage: "rectangle.dashed") { newGroupLabel = ""; isPresentingAddGroupAlert = true }
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("Add Card")
    }

    private var connectToggleButton: some View {
        Button {
            isConnecting.toggle()
            connectingFromCard = nil
        } label: {
            Image(systemName: isConnecting ? "link.circle.fill" : "link.circle")
        }
        .accessibilityLabel(isConnecting ? "Stop Connecting" : "Connect Cards")
    }

    private var exportButton: some View {
        Button {
            isPresentingExport = true
        } label: {
            Label("Export Canvas…", systemImage: "square.and.arrow.up")
        }
    }

    private func handleTap(_ card: CanvasCard) {
        if isConnecting {
            guard let fromCard = connectingFromCard else {
                connectingFromCard = card
                return
            }
            if fromCard.canvasCardId != card.canvasCardId {
                if board.boundDocumentId != nil, fromCard.canvasCardType == .note, card.canvasCardType == .note {
                    // Bound board (Decision 9(a)): a note-to-note connector must correspond to a
                    // real `[[link]]`, so confirm-then-write the link rather than drawing a
                    // connector reconciliation would immediately treat as spurious and remove.
                    pendingConnector = (from: fromCard, to: card)
                } else {
                    viewModel.addConnector(from: fromCard, to: card)
                }
            }
            connectingFromCard = nil
            return
        }

        switch card.canvasCardType {
        case .note:
            guard let documentId = card.documentId, let document = Document.fetch(syncId: documentId, in: modelContext) else { return }
            navigationTarget = document
        case .media:
            guard let attachmentId = card.attachmentId, let attachment = Attachment.fetch(syncId: attachmentId, in: modelContext) else { return }
            previewedAttachment = attachment
        case .web:
            guard let url = card.url, let webURL = URL(string: url) else { return }
            openURL(webURL)
        case .group, .none:
            break
        }
    }

    /// Extracted out of `body`'s `ZStack`, alongside `cardsLayer`/`cardView(for:)`/
    /// `cardCenter(of:)` below: the compiler timed out type-checking the pan-gesture background,
    /// the card `ForEach`, and their surrounding modifiers all inline in one `ZStack` — a known
    /// Swift complexity cliff, not a logic issue. Splitting each into its own (still simple)
    /// sub-expression fixes it.
    private var panBackground: some View {
        Color.noteBytezSecondarySurface.opacity(0.4)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .updating($panDelta) { value, state, _ in state = value.translation }
                    .onEnded { value in
                        offset.width += value.translation.width
                        offset.height += value.translation.height
                    }
            )
    }

    private var cardsLayer: some View {
        ForEach(viewModel.cards) { card in
            cardView(for: card)
                .position(cardCenter(of: card))
        }
    }

    @ViewBuilder
    private func cardView(for card: CanvasCard) -> some View {
        CanvasCardView(
            card: card,
            isConnecting: connectingFromCard?.canvasCardId == card.canvasCardId,
            onTap: { handleTap(card) },
            onMove: { x, y in viewModel.moveCard(card, x: x, y: y) },
            onResize: { width, height in viewModel.resizeCard(card, width: width, height: height) },
            onRemove: { viewModel.removeCard(card) }
        )
    }

    private func cardCenter(of card: CanvasCard) -> CGPoint {
        let width = card.width ?? CanvasDAL.defaultCardWidth
        let height = card.height ?? CanvasDAL.defaultCardHeight
        let x = (card.positionX ?? 0) + width / 2
        let y = (card.positionY ?? 0) + height / 2
        return CGPoint(x: x, y: y)
    }

    // MARK: - Connector-creates-link (C6)

    private var pendingConnectorMessage: String {
        guard let pending = pendingConnector,
              let fromDocument = pending.from.documentId.flatMap({ Document.fetch(syncId: $0, in: modelContext) }),
              let toDocument = pending.to.documentId.flatMap({ Document.fetch(syncId: $0, in: modelContext) })
        else { return "" }
        return "Add [[\(toDocument.title ?? "Untitled")]] to \(fromDocument.title ?? "Untitled")?"
    }

    private func confirmPendingConnector() {
        defer { pendingConnector = nil }
        guard let pending = pendingConnector,
              let fromDocument = pending.from.documentId.flatMap({ Document.fetch(syncId: $0, in: modelContext) }),
              let toDocument = pending.to.documentId.flatMap({ Document.fetch(syncId: $0, in: modelContext) }),
              let toTitle = toDocument.title
        else { return }

        DocumentDAL.appendWikilink(to: fromDocument, title: toTitle, in: modelContext)
        viewModel.reload()
    }

}

private struct AddNoteCardSheet: View {

    var viewModel: CanvasViewModel
    @Binding var isPresented: Bool
    let origin: (x: Double, y: Double)
    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            List(viewModel.noteCardCandidates(matching: query)) { document in
                Button {
                    guard let documentId = document.documentId else { return }
                    viewModel.addNoteCard(documentId: documentId, x: origin.x, y: origin.y)
                    isPresented = false
                } label: {
                    Text(document.title?.isEmpty == false ? document.title! : "Untitled")
                }
            }
            .searchable(text: $query, prompt: "Search notes")
            .navigationTitle("Add Note")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

}

private struct AddMediaCardSheet: View {

    var viewModel: CanvasViewModel
    @Binding var isPresented: Bool
    let origin: (x: Double, y: Double)

    @Environment(\.modelContext) private var modelContext

    private func ownerTitle(for attachment: Attachment) -> String {
        guard let documentId = attachment.documentId, let document = Document.fetch(syncId: documentId, in: modelContext) else { return "" }
        return document.title ?? ""
    }

    var body: some View {
        NavigationStack {
            List(viewModel.mediaCardCandidates()) { attachment in
                Button {
                    guard let attachmentId = attachment.attachmentId else { return }
                    viewModel.addMediaCard(attachmentId: attachmentId, x: origin.x, y: origin.y)
                    isPresented = false
                } label: {
                    VStack(alignment: .leading) {
                        Text(attachment.fileName ?? "Attachment")
                        Text(ownerTitle(for: attachment))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if viewModel.mediaCardCandidates().isEmpty {
                    ContentUnavailableView("No Attachments Yet", systemImage: "paperclip", description: Text("Attach a file to a note first."))
                }
            }
            .navigationTitle("Add Media")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

}

/// Picks the note a board binds to (C5) — same fuzzy-search shape as `AddNoteCardSheet`, reused
/// from both `CanvasBoardView`'s toolbar and `CanvasBoardListView`'s row context menu.
struct BindBoardSheet: View {

    var viewModel: CanvasViewModel
    let board: CanvasBoard
    @Binding var isPresented: Bool
    @State private var query: String = ""

    var body: some View {
        NavigationStack {
            List(viewModel.noteCardCandidates(matching: query)) { document in
                Button {
                    guard document.documentId != nil else { return }
                    viewModel.bind(board, to: document)
                    isPresented = false
                } label: {
                    Text(document.title?.isEmpty == false ? document.title! : "Untitled")
                }
            }
            .searchable(text: $query, prompt: "Search notes")
            .navigationTitle("Bind to Note")
            .noteBytezInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
    }

}
