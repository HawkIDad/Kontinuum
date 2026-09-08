// © Copyright, 2026 David L. Collison, All Rights Reserved.
//
//  CanvasBoardListView.swift
//  NoteBytez
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// Library-scoped list of every `CanvasBoard` — mirrors `NotebookBrowserView.swift`'s exact
/// list/create shape, since `CanvasBoard` is library-scoped the same way Notebooks are (per
/// UIUX/04-InteractionDesign.md's own note). Tapping a board drills into `CanvasBoardView` (S16).
struct CanvasBoardListView: View {

    var viewModel: CanvasViewModel

    @State private var isPresentingCreateBoard = false
    @State private var isPresentingImporter = false
    @State private var bindingTarget: CanvasBoard?

    var body: some View {
        List {
            if viewModel.boards.isEmpty {
                ContentUnavailableView(
                    "No Canvas Boards Yet",
                    systemImage: "square.grid.2x2",
                    description: Text("Create a board, or import a .canvas file.")
                )
            } else {
                ForEach(viewModel.boards) { board in
                    NavigationLink {
                        CanvasBoardView(viewModel: viewModel, board: board)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Label(board.name ?? "Untitled Board", systemImage: "square.grid.2x2")
                            if let boundTitle = viewModel.boundDocumentTitle(for: board) {
                                Text("↔ \(boundTitle)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .accessibilityLabel("Bound to \(boundTitle)")
                            }
                        }
                    }
                    .contextMenu {
                        if board.boundDocumentId != nil {
                            Button("Unbind", systemImage: "link.badge.minus") { viewModel.unbind(board) }
                        } else {
                            Button("Bind to Note…", systemImage: "link.badge.plus") { bindingTarget = board }
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets { viewModel.deleteBoard(viewModel.boards[index]) }
                }
            }
        }
        .navigationTitle("Canvas")
        .noteBytezInlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingCreateBoard = true
                } label: {
                    Label("New Board", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    isPresentingImporter = true
                } label: {
                    Label("Import Canvas…", systemImage: "square.and.arrow.down")
                }
            }
        }
        .onAppear {
            viewModel.loadBoards()
        }
        .sheet(isPresented: $isPresentingCreateBoard) {
            CreateCanvasBoardSheet(viewModel: viewModel, isPresented: $isPresentingCreateBoard)
        }
        .sheet(item: $bindingTarget) { board in
            BindBoardSheet(viewModel: viewModel, board: board, isPresented: Binding(get: { bindingTarget != nil }, set: { if !$0 { bindingTarget = nil } }))
        }
        .fileImporter(isPresented: $isPresentingImporter, allowedContentTypes: [UTType(filenameExtension: "canvas") ?? .json]) { result in
            guard let fileURL = try? result.get() else { return }
            let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
            defer { if didStartAccessing { fileURL.stopAccessingSecurityScopedResource() } }
            guard let jsonString = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
            viewModel.importBoard(named: fileURL.deletingPathExtension().lastPathComponent, jsonString: jsonString)
        }
        .onReceive(NotificationCenter.default.publisher(for: .noteBytezTriggerNewCanvasBoard)) { _ in
            isPresentingCreateBoard = true
        }
    }

}

private struct CreateCanvasBoardSheet: View {

    var viewModel: CanvasViewModel
    @Binding var isPresented: Bool
    @State private var name: String = ""

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Board Name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                PrimaryButton(title: "Create") {
                    viewModel.createBoard(name: name)
                    isPresented = false
                }
                .disabled(!isNameValid)

                SecondaryButton(title: "Cancel") {
                    isPresented = false
                }
            }
            .padding(.top, 24)
            .navigationTitle("New Board")
            .noteBytezInlineNavigationTitle()
        }
    }

}
